import 'dart:io';

import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/assignment.dart';
import '../models/enums.dart';
import '../models/subject.dart';
import 'file_storage_service.dart';
import 'semester_service.dart';

class AssignmentService {
  AssignmentService._();
  static final AssignmentService instance = AssignmentService._();

  Isar get _db => IsarService.instance.db;

  /// Soonest deadline first — the whole point of a deadline list is
  /// seeing what's due next.
  Stream<List<Assignment>> watchForSubject(int subjectId) {
    return _db.assignments
        .filter()
        .subjectIdEqualTo(subjectId)
        .watch(fireImmediately: true)
        .map((list) => list..sort((a, b) => a.deadline.compareTo(b.deadline)));
  }

  Future<Assignment> upload({
    required Subject subject,
    required String title,
    required DateTime deadline,
    required File pdfFile,
  }) async {
    final semester = await SemesterService.instance.getById(subject.semesterId);
    final semesterNumber = semester?.semesterNumber ?? 0;

    final dir = await FileStorageService.instance.subjectSectionDir(
      semesterNumber: semesterNumber,
      subjectName: subject.name,
      section: 'Assignments',
    );

    final originalName = pdfFile.uri.pathSegments.isNotEmpty
        ? pdfFile.uri.pathSegments.last
        : pdfFile.path;

    final storedPath = await FileStorageService.instance.copyWithUniqueName(
      source: pdfFile,
      destinationDir: dir,
      fileName: originalName,
    );
    final storedName = storedPath.split('/').last;

    final assignment = Assignment()
      ..subjectId = subject.id
      ..title = title.trim().isEmpty ? storedName : title.trim()
      ..fileName = storedName
      ..filePath = storedPath
      ..deadline = deadline
      ..status = AssignmentStatus.pending;

    await _db.writeTxn(() async {
      await _db.assignments.put(assignment);
    });
    return assignment;
  }

  Future<void> setStatus(Assignment assignment, AssignmentStatus status) async {
    assignment.status = status;
    await _db.writeTxn(() async {
      await _db.assignments.put(assignment);
    });
  }

  Future<void> delete(Assignment assignment) async {
    await FileStorageService.instance.deleteIfExists(assignment.filePath);
    await _db.writeTxn(() async {
      await _db.assignments.delete(assignment.id);
    });
  }
}
