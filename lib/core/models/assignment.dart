import 'package:isar/isar.dart';

import 'enums.dart';

part 'assignment.g.dart';

/// One assignment inside a subject's Assignment Manager (Phase 14):
/// an uploaded PDF, a deadline, and a Pending/Submitted status. Like
/// Resource, only metadata + path lives in Isar — the PDF bytes stay
/// on disk under `Subject/Assignments/`.
@collection
class Assignment {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  late String title;

  late String fileName;
  late String filePath;

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
