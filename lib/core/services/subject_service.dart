import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/enums.dart';
import '../models/subject.dart';
import 'assignment_service.dart';
import 'chat_service.dart';
import 'file_storage_service.dart';
import 'lecture_service.dart';
import 'note_service.dart';
import 'resource_service.dart';
import 'semester_service.dart';
import 'syllabus_service.dart';
import 'timetable_service.dart';

class SubjectService {
  SubjectService._();
  static final SubjectService instance = SubjectService._();

  Isar get _db => IsarService.instance.db;

  Stream<List<Subject>> watchForSemester(int semesterId) {
    return _db.subjects
        .filter()
        .semesterIdEqualTo(semesterId)
        .sortByName()
        .watch(fireImmediately: true);
  }

  Future<List<Subject>> getForSemester(int semesterId) {
    return _db.subjects
        .filter()
        .semesterIdEqualTo(semesterId)
        .sortByName()
        .findAll();
  }

  /// Case-insensitive find-or-create — timetable rows for the same
  /// subject (e.g. "DBMS" appearing on Monday and Wednesday) must map
  /// to a single Subject, not a duplicate per row.
  Future<Subject> getOrCreate({
    required String name,
    required int semesterId,
  }) async {
    final trimmed = name.trim();
    final existing = await _db.subjects
        .filter()
        .semesterIdEqualTo(semesterId)
        .nameEqualTo(trimmed, caseSensitive: false)
        .findFirst();
    if (existing != null) return existing;

    final subject = Subject()
      ..semesterId = semesterId
      ..name = trimmed;

    await _db.writeTxn(() async {
      await _db.subjects.put(subject);
    });
    return subject;
  }

  /// Deletes [subject] and everything under it: timetable slots,
  /// lectures (all three sections + their photos), resources, the
  /// syllabus, assignments, notes, and AI chat history — plus the
  /// subject's whole folder on disk, so nothing orphaned is left behind
  /// either in Isar or in storage. There's no undo once this runs; the
  /// confirmation lives in the UI (Subject Workspace's overflow menu),
  /// not here.
  Future<void> delete(Subject subject) async {
    final semester = await SemesterService.instance.getById(subject.semesterId);

    final timetableEntries =
        await TimetableService.instance.watchForSubject(subject.id).first;
    for (final entry in timetableEntries) {
      await TimetableService.instance.delete(entry);
    }

    for (final sessionType in SessionType.values) {
      final lectures = await LectureService.instance
          .watchForSection(subjectId: subject.id, sessionType: sessionType)
          .first;
      for (final lecture in lectures) {
        await LectureService.instance.delete(lecture);
      }
    }

    final resources =
        await ResourceService.instance.watchForSubject(subject.id).first;
    for (final resource in resources) {
      await ResourceService.instance.delete(resource);
    }

    final syllabus = await SyllabusService.instance.getForSubject(subject.id);
    if (syllabus != null) {
      await SyllabusService.instance.delete(syllabus);
    }

    final assignments =
        await AssignmentService.instance.watchForSubject(subject.id).first;
    for (final assignment in assignments) {
      await AssignmentService.instance.delete(assignment);
    }

    final notes = await NoteService.instance.getForSubject(subject.id);
    for (final note in notes) {
      await NoteService.instance.delete(note);
    }

    await ChatService.instance.clearHistory(subject.id);

    // Catches anything left over — empty subfolders, or a file whose
    // row somehow failed to delete above.
    if (semester != null) {
      await FileStorageService.instance.deleteSubjectDir(
        semesterNumber: semester.semesterNumber,
        subjectName: subject.name,
      );
    }

    await _db.writeTxn(() async {
      await _db.subjects.delete(subject.id);
    });
  }

  Future<Subject?> getById(int id) => _db.subjects.get(id);

  /// Used by the Subject Workspace (Phase 4) header so a code edit made
  /// from the workspace shows up immediately without a manual refresh.
  Stream<Subject?> watchById(int id) =>
      _db.subjects.watchObject(id, fireImmediately: true);

  /// Sets/clears the short code used for Lecture Upload IDs in Phase 7
  /// (e.g. "DBMS" -> DBMS_T_005). Blank input clears the code.
  Future<void> updateCode(Subject subject, String? code) async {
    final trimmed = code?.trim();
    subject.code = (trimmed == null || trimmed.isEmpty)
        ? null
        : trimmed.toUpperCase();
    await _db.writeTxn(() async {
      await _db.subjects.put(subject);
    });
  }

  /// Phase 13 (Dashboard) — "Pinned Subjects".
  Future<void> togglePin(Subject subject) async {
    subject.isPinned = !subject.isPinned;
    await _db.writeTxn(() async {
      await _db.subjects.put(subject);
    });
  }

  Stream<List<Subject>> watchPinnedForSemester(int semesterId) {
    return _db.subjects
        .filter()
        .semesterIdEqualTo(semesterId)
        .isPinnedEqualTo(true)
        .sortByName()
        .watch(fireImmediately: true);
  }
}