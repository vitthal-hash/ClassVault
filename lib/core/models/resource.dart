import 'package:isar/isar.dart';

import 'enums.dart';

part 'resource.g.dart';

/// One uploaded file in a subject's Resource Manager (Phase 6): a PDF,
/// PPT, Word doc, or image. Per the plan, the database only ever stores
/// name/path/subject/type/extracted-text — the bytes stay on disk under
/// `Subject/Resources/<Type>/`, never duplicated into Isar.
@collection
class Resource {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  /// Display name — the file's name as stored on disk (already made
  /// unique within its folder if another file shared the name).
  late String name;

  late String filePath;

  @enumerated
  late ResourceType type;

  /// Populated for PDF (direct text) and Image (OCR) uploads. PPT/Word
  /// stay null until their own text extractor is built later.
  String? extractedText;

  DateTime uploadedAt = DateTime.now();
}
