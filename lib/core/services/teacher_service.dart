import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/teacher.dart';

class TeacherService {
  TeacherService._();
  static final TeacherService instance = TeacherService._();

  Isar get _db => IsarService.instance.db;

  Future<List<Teacher>> getAll() => _db.teachers.where().sortByName().findAll();

  /// Used by the Subject Workspace schedule tabs (Phase 4) to resolve a
  /// TimetableEntry's `teacherId` back into a display name.
  Future<Teacher?> getById(int id) => _db.teachers.get(id);

  /// Case-insensitive find-or-create — "Prof. Sharma" seen on two
  /// different timetable rows should be one Teacher record, not two.
  Future<Teacher> getOrCreate(String name) async {
    final trimmed = name.trim();
    final existing =
        await _db.teachers.filter().nameEqualTo(trimmed, caseSensitive: false).findFirst();
    if (existing != null) return existing;

    final teacher = Teacher()..name = trimmed;
    await _db.writeTxn(() async {
      await _db.teachers.put(teacher);
    });
    return teacher;
  }
}
