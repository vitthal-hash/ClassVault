import '../models/enums.dart';
import '../models/subject.dart';
import 'subject_service.dart';
import 'timetable_service.dart';

/// Phase 8 — Smart Subject Detection.
///
/// The plan's two cases:
/// 1. Upload at Monday 10:10, timetable says DBMS at that time -> the
///    subject/session is suggested automatically, one tap to confirm.
/// 2. Upload at 9 PM with nothing scheduled -> the person is asked to
///    choose the subject; once chosen, the session type still gets
///    picked automatically ("If Lab timing, store DBMS -> Lab.
///    Otherwise Theory.").
class SmartDetectionService {
  SmartDetectionService._();
  static final SmartDetectionService instance = SmartDetectionService._();

  /// Case 1. Returns null when nothing is scheduled right now — the
  /// caller should fall through to asking the person to choose.
  Future<DetectedSlot?> detectNow({required int semesterId}) async {
    final now = DateTime.now();
    final entry = await TimetableService.instance.findSlotAt(
      semesterId: semesterId,
      day: WeekdayX.fromDateTime(now),
      minutesSinceMidnight: now.hour * 60 + now.minute,
    );
    if (entry == null) return null;

    final subject = await SubjectService.instance.getById(entry.subjectId);
    if (subject == null) return null;

    return DetectedSlot(subject: subject, sessionType: entry.sessionType);
  }

  /// Case 2's session-type half, once the person has picked the
  /// subject manually.
  Future<SessionType> fallbackSessionType({required Subject subject}) async {
    final now = DateTime.now();
    final isLabTime = await TimetableService.instance.hasLabAtTimeOfDay(
      subjectId: subject.id,
      minutesSinceMidnight: now.hour * 60 + now.minute,
    );
    return isLabTime ? SessionType.lab : SessionType.theory;
  }
}

/// What was found scheduled right now.
class DetectedSlot {
  DetectedSlot({required this.subject, required this.sessionType});

  final Subject subject;
  final SessionType sessionType;
}
