import 'package:isar/isar.dart';

import 'enums.dart';

part 'timetable_entry.g.dart';

/// One slot in the weekly timetable, e.g.
/// "Monday 09:00-10:00 · DBMS · Theory · Prof. Sharma".
@collection
class TimetableEntry {
  Id id = Isar.autoIncrement;

  @Index()
  late int semesterId;

  @Index()
  late int subjectId;

  int? teacherId;

  @enumerated
  late Weekday day;

  /// Minutes since midnight, e.g. 09:00 -> 540. Makes sorting/overlap
  /// checks trivial without parsing strings every time.
  late int startMinutes;
  late int endMinutes;

  @enumerated
  late SessionType sessionType;

  String? room;

  DateTime createdAt = DateTime.now();

  @ignore
  String get timeRangeLabel =>
      '${_fmt(startMinutes)} - ${_fmt(endMinutes)}';

  static String _fmt(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}
