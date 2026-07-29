import 'dart:io';

import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/assignment.dart';
import '../models/enums.dart';
import '../models/subject.dart';
import 'file_storage_service.dart';
import 'reminder_service.dart';
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

  /// Looked up by id (not subjectId) because ReminderService's
  /// notification-action handler only has the assignment id — it comes
  /// from the tapped notification's payload, not from a screen that
  /// already has the Subject in hand.
  Future<Assignment?> getById(int id) => _db.assignments.get(id);

  /// [file] is optional — an assignment can be created as a deadline-only
  /// reminder with nothing attached, and a file (PDF or Word) added
  /// later isn't supported yet, so for now it's "attach now or never."
  Future<Assignment> upload({
    required Subject subject,
    required String title,
    required DateTime deadline,
    File? file,
  }) async {
    String? storedPath;
    String? storedName;

    if (file != null) {
      final semester = await SemesterService.instance.getById(subject.semesterId);
      final semesterNumber = semester?.semesterNumber ?? 0;

      final dir = await FileStorageService.instance.subjectSectionDir(
        semesterNumber: semesterNumber,
        subjectName: subject.name,
        section: 'Assignments',
      );

      final originalName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path;

      storedPath = await FileStorageService.instance.copyWithUniqueName(
        source: file,
        destinationDir: dir,
        fileName: originalName,
      );
      storedName = storedPath.split('/').last;
    }

    final assignment = Assignment()
      ..subjectId = subject.id
      ..title = title.trim().isEmpty ? (storedName ?? 'Untitled assignment') : title.trim()
      ..fileName = storedName
      ..filePath = storedPath
      ..deadline = deadline
      ..status = AssignmentStatus.pending;

    await _db.writeTxn(() async {
      await _db.assignments.put(assignment);
    });
    await ReminderService.instance.scheduleAssignmentReminders(assignment);
    return assignment;
  }

  /// Marking Submitted cancels every pending reminder (day-before,
  /// due-date, and any "I'll do it" snooze) — nothing left to nag
  /// about. Reverting to Pending re-schedules them against whatever's
  /// still ahead on the deadline.
  Future<void> setStatus(Assignment assignment, AssignmentStatus status) async {
    assignment.status = status;
    await _db.writeTxn(() async {
      await _db.assignments.put(assignment);
    });
    if (status == AssignmentStatus.submitted) {
      await ReminderService.instance.cancelAssignmentReminders(assignment.id);
    } else {
      await ReminderService.instance.scheduleAssignmentReminders(assignment);
    }
  }

  Future<void> delete(Assignment assignment) async {
    await ReminderService.instance.cancelAssignmentReminders(assignment.id);
    final path = assignment.filePath;
    if (path != null) {
      await FileStorageService.instance.deleteIfExists(path);
    }
    await _db.writeTxn(() async {
      await _db.assignments.delete(assignment.id);
    });
  }
}