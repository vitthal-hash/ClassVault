import 'package:isar/isar.dart';

import 'enums.dart';

part 'assignment.g.dart';

/// One assignment inside a subject's Assignment Manager (Phase 14): a
/// title, a deadline, a Pending/Submitted status, and an *optional*
/// attached file (PDF or Word). Like Resource, only metadata + path
/// lives in Isar — file bytes stay on disk under `Subject/Assignments/`
/// when there is a file at all.
@collection
class Assignment {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  late String title;

  /// Both null for a deadline-only entry with no file attached — the
  /// "don't make the upload compulsory" change. A Pending/Submitted
  /// assignment can exist purely as a reminder of something to do by a
  /// date, same as it always could when it did have a file.
  String? fileName;
  String? filePath;

  @Index()
  late DateTime deadline;

  @enumerated
  AssignmentStatus status = AssignmentStatus.pending;

  DateTime createdAt = DateTime.now();

  /// Derived, never stored: a pending assignment past its deadline is
  /// overdue. Marking it Submitted (even late) clears this immediately
  /// since it only checks `status`.
  @ignore
  bool get isOverdue =>
      status == AssignmentStatus.pending && DateTime.now().isAfter(deadline);
}