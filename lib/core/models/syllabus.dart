import 'package:isar/isar.dart';

part 'syllabus.g.dart';

/// A subject's syllabus PDF (Phase 5). One per subject — uploading again
/// replaces the previous file and re-extracts the text, it doesn't add
/// a second record.
@collection
class Syllabus {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late int subjectId;

  late String fileName;

  /// Absolute path under the app's AcademicAssistant/ folder structure.
  late String filePath;

  /// Extracted once at upload time and reused everywhere else (Search in
  /// Phase 12, Subject AI Chat in Phase 11) so the PDF is never re-parsed.
  String? extractedText;

  DateTime uploadedAt = DateTime.now();
}
