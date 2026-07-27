import 'package:isar/isar.dart';

import 'enums.dart';

part 'lecture.g.dart';

/// One captured lecture photo (Phase 7): "DBMS -> Theory -> + -> Camera
/// or Gallery" per the plan. Auto-generates a human-readable ID like
/// `DBMS_T_005` (subject code + session initial + running count).
///
/// `ocrText` is included now but only ever populated starting in
/// Phase 9 (OCR) — same forward-declared-field pattern as `Subject.code`
/// being added in Phase 4 ahead of its Phase 7 use.
@collection
class Lecture {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  @Index()
  @enumerated
  late SessionType sessionType;

  /// e.g. "DBMS_T_005" — generated once at capture time, never changes.
  late String lectureCode;

  late String imagePath;

  /// When the photo was actually taken/picked, as opposed to [createdAt]
  /// which is when the row was written (normally the same instant, but
  /// kept separate in case a future edit flow lets the date be fixed).
  late DateTime capturedAt;

  DateTime createdAt = DateTime.now();

  /// Phase 15 (Revision): "Star lecture -> Creates Revision Folder."
  /// There's no separate folder/table for this — a starred lecture IS
  /// the revision folder's contents, the same forward-compatible
  /// pattern as `Subject.isPinned` for Home's Pinned Subjects.
  @Index()
  bool isStarred = false;

  /// Populated from Phase 9 onward by running OCR on [imagePath].
  String? ocrText;
}
