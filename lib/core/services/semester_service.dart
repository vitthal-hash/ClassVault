import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/semester.dart';
import 'subject_service.dart';

/// All reads/writes for Semester data go through here — screens never
/// touch Isar directly.
class SemesterService {
  SemesterService._();
  static final SemesterService instance = SemesterService._();

  Isar get _db => IsarService.instance.db;

  /// Live list of every semester, newest first. Widgets can listen to
  /// this and rebuild automatically whenever a semester is added/edited.
  Stream<List<Semester>> watchAll() {
    return _db.semesters
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true);
  }

  Future<List<Semester>> getAll() {
    return _db.semesters.where().sortByCreatedAtDesc().findAll();
  }

  Future<Semester?> getActive() {
    return _db.semesters.filter().isActiveEqualTo(true).findFirst();
  }

  Future<Semester?> getById(int id) => _db.semesters.get(id);

  /// Creates a new semester and makes it the active one (any previously
  /// active semester is kept, just marked inactive — history isn't lost).
  Future<Semester> createSemester({
    required String name,
    required int semesterNumber,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final semester = Semester()
      ..name = name
      ..semesterNumber = semesterNumber
      ..startDate = startDate
      ..endDate = endDate
      ..isActive = true;

    await _db.writeTxn(() async {
      // Deactivate whatever was active before.
      final current = await _db.semesters
          .filter()
          .isActiveEqualTo(true)
          .findAll();
      for (final s in current) {
        s.isActive = false;
        await _db.semesters.put(s);
      }
      await _db.semesters.put(semester);
    });

    return semester;
  }

  Future<void> setActive(Semester semester) async {
    await _db.writeTxn(() async {
      final all = await _db.semesters.where().findAll();
      for (final s in all) {
        s.isActive = s.id == semester.id;
        await _db.semesters.put(s);
      }
    });
  }

  /// Deletes [semester] and, since a subject can't outlive its
  /// semester, every subject inside it too — each subject deletion
  /// itself cascades through its timetable slots, lectures, resources,
  /// syllabus, assignments, notes, and chat history (see
  /// `SubjectService.delete`), so nothing is left orphaned.
  Future<void> delete(Semester semester) async {
    final subjects = await SubjectService.instance.getForSemester(semester.id);
    for (final subject in subjects) {
      await SubjectService.instance.delete(subject);
    }
    await _db.writeTxn(() async {
      await _db.semesters.delete(semester.id);
    });
  }
}