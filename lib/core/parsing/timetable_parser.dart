import '../models/enums.dart';

/// One row parsed out of raw timetable text. This is NOT an Isar model —
/// it's a draft the user reviews/edits before anything gets saved to the
/// database. Day/time/subject fields are nullable/blank when the parser
/// couldn't confidently detect them, so the review screen can flag them.
class ParsedTimetableRow {
  ParsedTimetableRow({
    this.day,
    this.startMinutes,
    this.endMinutes,
    required this.subjectName,
    this.sessionType = SessionType.theory,
    this.teacherName,
    this.room,
    required this.sourceLine,
  });

  Weekday? day;
  int? startMinutes;
  int? endMinutes;
  String subjectName;
  SessionType sessionType;
  String? teacherName;
  String? room;

  /// The original line this row came from — shown in the review UI so
  /// the person can double-check against the source if something looks off.
  final String sourceLine;

  bool get isComplete =>
      day != null &&
      startMinutes != null &&
      endMinutes != null &&
      subjectName.trim().isNotEmpty;
}

/// Heuristic line-by-line parser for timetable text extracted via OCR
/// (images) or direct text extraction (PDFs). Timetables come in wildly
/// different layouts, so this makes a best effort per line and always
/// hands the result to the person for a quick review rather than
/// silently trusting it — the plan's "no manual work" goal is best
/// served by getting 80% right automatically and making the other 20%
/// a one-tap fix, not by pretending the OCR is always perfect.
class TimetableParser {
  TimetableParser._();

  static final _dayRegex = RegExp(
    r'\b(mon|monday|tue|tues|tuesday|wed|wednesday|thu|thur|thurs|thursday|fri|friday|sat|saturday|sun|sunday)\b',
    caseSensitive: false,
  );

  // Matches things like "9:00-10:00", "09.00 - 10.00", "9am-10am", "9:00 to 10:00"
  static final _timeRangeRegex = RegExp(
    r'(\d{1,2})[:.]?(\d{2})?\s*(am|pm)?\s*(?:-|to|–)\s*(\d{1,2})[:.]?(\d{2})?\s*(am|pm)?',
    caseSensitive: false,
  );

  static final _sessionRegex = RegExp(
    r'\b(theory|lab|laboratory|practical|tutorial|tut)\b',
    caseSensitive: false,
  );

  // "Prof. Sharma", "Dr Mehta", "Mr. Rao", "Ms Iyer", "Mrs. Nair"
  static final _teacherRegex = RegExp(
    r'\b(prof\.?|dr\.?|mr\.?|mrs\.?|ms\.?)\s+([A-Z][a-zA-Z.\s]{1,30}?)(?=\s{2,}|$|[,;()])',
    caseSensitive: false,
  );

  static List<ParsedTimetableRow> parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final rows = <ParsedTimetableRow>[];

    for (final line in lines) {
      // Skip obvious headers/noise lines with no digits and no day name.
      final looksRelevant =
          _dayRegex.hasMatch(line) || RegExp(r'\d').hasMatch(line);
      if (!looksRelevant) continue;

      String working = line;

      final day = _extractDay(working);

      final timeMatch = _timeRangeRegex.firstMatch(working);
      int? start, end;
      if (timeMatch != null) {
        start = _toMinutes(timeMatch.group(1), timeMatch.group(2), timeMatch.group(3));
        end = _toMinutes(timeMatch.group(4), timeMatch.group(5), timeMatch.group(6));
        working = working.replaceRange(timeMatch.start, timeMatch.end, ' ');
      }

      SessionType sessionType = SessionType.theory;
      final sessionMatch = _sessionRegex.firstMatch(working);
      if (sessionMatch != null) {
        sessionType = SessionTypeX.fromText(sessionMatch.group(0)!);
        working = working.replaceRange(sessionMatch.start, sessionMatch.end, ' ');
      }

      String? teacher;
      final teacherMatch = _teacherRegex.firstMatch(working);
      if (teacherMatch != null) {
        teacher = teacherMatch.group(0)?.trim();
        working = working.replaceRange(teacherMatch.start, teacherMatch.end, ' ');
      }

      // Strip the day word itself out of the leftover text too.
      working = working.replaceAll(_dayRegex, ' ');

      // Whatever's left, cleaned up, is our best guess at the subject name.
      final subjectName = working
          .replaceAll(RegExp(r'[|:•\-–—]+'), ' ')
          .replaceAll(RegExp(r'\s{2,}'), ' ')
          .trim();

      if (subjectName.isEmpty && day == null && timeMatch == null) {
        // Nothing usable on this line at all — skip rather than add junk.
        continue;
      }

      rows.add(ParsedTimetableRow(
        day: day,
        startMinutes: start,
        endMinutes: end,
        subjectName: subjectName.isEmpty ? 'Untitled Subject' : subjectName,
        sessionType: sessionType,
        teacherName: teacher,
        sourceLine: line,
      ));
    }

    return rows;
  }

  static Weekday? _extractDay(String text) {
    final match = _dayRegex.firstMatch(text);
    if (match == null) return null;
    return WeekdayX.fromText(match.group(0)!);
  }

  static int? _toMinutes(String? hourStr, String? minStr, String? ampm) {
    if (hourStr == null) return null;
    int hour = int.tryParse(hourStr) ?? 0;
    final minute = int.tryParse(minStr ?? '0') ?? 0;
    if (ampm != null) {
      final isPm = ampm.toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
    } else if (hour < 8) {
      // Heuristic: college classes rarely start before 8am — a bare "1"
      // or "2" with no am/pm almost always means 1pm/2pm on a timetable.
      hour += 12;
    }
    return hour * 60 + minute;
  }
}
