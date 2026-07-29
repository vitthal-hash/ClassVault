import 'package:isar/isar.dart';

part 'note.g.dart';

/// A quick, free-form note the person writes themselves — e.g. "what
/// was taught in that lecture that day" — as opposed to a Lecture
/// (Phase 7), which is always a captured photo run through OCR. Notes
/// are plain typed text, available from anywhere inside a subject via
/// a persistent "+" action, not tied to a specific Theory/Lab/Tutorial
/// section the way lectures are.
@collection
class Note {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  /// Optional short title. When left blank, the notes list falls back
  /// to showing the first line of [body] instead.
  String? title;

  late String body;

  DateTime createdAt = DateTime.now();

  @Index()
  DateTime updatedAt = DateTime.now();

  /// Phase 17 (Reminders): when on, ReminderService schedules a
  /// recurring notification the evening before every occurrence of
  /// this note's subject on the timetable. Off by default — most notes
  /// are just free-form scratch, not something worth a nudge for.
  bool remindMe = false;
}