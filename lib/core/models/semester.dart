import 'package:isar/isar.dart';

part 'semester.g.dart';

/// One semester (e.g. "Semester 3"). Everything else in the app —
/// subjects, timetable, lectures — hangs off of a Semester.
@collection
class Semester {
  Id id = Isar.autoIncrement;

  /// e.g. "Semester 3" or a custom name the user typed.
  late String name;

  /// e.g. 3 — used for sorting and for auto-naming ("Semester 3").
  late int semesterNumber;

  late DateTime startDate;
  late DateTime endDate;

  /// Only one semester is "active" at a time — the one whose subjects
  /// show up on Home/Subjects by default. Older semesters stay in the
  /// database so past work is never lost.
  bool isActive = true;

  DateTime createdAt = DateTime.now();

  @ignore
  bool get hasEnded => DateTime.now().isAfter(endDate);
}
