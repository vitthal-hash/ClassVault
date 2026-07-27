import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../models/assignment.dart';
import '../models/app_settings.dart';
import '../models/chat_message.dart';
import '../models/note.dart';
import '../models/semester.dart';
import '../models/lecture.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/syllabus.dart';
import '../models/teacher.dart';
import '../models/timetable_entry.dart';

/// Single source of truth for the Isar instance.
///
/// Phase 1: opens the database with an empty schema list just to prove
/// Isar boots correctly and the app can read/write to disk.
///
/// From Phase 2 onward, every new model (Semester, Subject, Timetable,
/// Lecture, ...) gets added to the `schemas` list below — nothing else
/// about this file changes.
class IsarService {
  IsarService._();
  static final IsarService instance = IsarService._();

  Isar? _isar;

  Isar get db {
    final isar = _isar;
    if (isar == null) {
      throw StateError(
        'Isar not initialized yet. Call IsarService.instance.init() '
        'before accessing IsarService.instance.db.',
      );
    }
    return isar;
  }

  bool get isReady => _isar != null;

  Future<void> init() async {
    if (_isar != null) return;

    final dir = await getApplicationDocumentsDirectory();

    _isar = await Isar.open(
      const [
        SemesterSchema,
        SubjectSchema,
        TeacherSchema,
        TimetableEntrySchema,
        SyllabusSchema,
        ResourceSchema,
        LectureSchema,
        ChatMessageSchema,
        AssignmentSchema,
        AppSettingsSchema,
        NoteSchema,
        // ...and so on for every model introduced later.
      ],
      directory: dir.path,
      name: 'academic_assistant_db',
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}