import 'package:isar/isar.dart';

part 'subject.g.dart';

/// A subject belongs to one semester. In Phase 3 these get created
/// automatically from the parsed timetable; Phase 4 turns each one into
/// a full workspace (Theory/Lab/Tutorial/Resources/Lectures/...).
@collection
class Subject {
  Id id = Isar.autoIncrement;

  @Index()
  late int semesterId;

  late String name;

  /// Optional short code, e.g. "DBMS" — used for IDs like DBMS_T_005
  /// generated during Lecture Upload (Phase 7).
  String? code;

  /// Phase 13 (Dashboard) — "Pinned Subjects": a person's own shortlist
  /// of subjects to surface on Home, independent of the timetable.
  @Index()
  bool isPinned = false;

  DateTime createdAt = DateTime.now();
}
