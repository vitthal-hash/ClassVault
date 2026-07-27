import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../utils/constants.dart';

/// Owns the on-disk folder layout described in the plan:
///
/// ```
/// AcademicAssistant/
///     Semester_3/
///         DBMS/
///             Syllabus/
///             Theory/Images/  Theory/OCR/
///             Lab/
///             PPTs/  PDFs/
///             Assignments/
/// ```
///
/// Isar only ever stores a `name` / `path` / metadata row — the actual
/// bytes always live here, never duplicated into the database.
class FileStorageService {
  FileStorageService._();
  static final FileStorageService instance = FileStorageService._();

  /// Public for Phase 16's `BackupService`, which needs to walk every
  /// file under here for a full local backup — everything else in this
  /// class only ever needed the private version.
  Future<Directory> rootDir() => _rootDir();

  Future<Directory> _rootDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory('${docs.path}/${AppConstants.rootFolderName}');
  }

  /// Filesystem-safe version of a subject/section name — subject names
  /// come from OCR/free text, so they can contain characters that are
  /// invalid in a folder name.
  String sanitize(String name) {
    final cleaned = name.trim().replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    return cleaned.isEmpty ? 'Untitled' : cleaned;
  }

  /// Returns (creating if needed) `Semester_X/SubjectName/section/`.
  Future<Directory> subjectSectionDir({
    required int semesterNumber,
    required String subjectName,
    required String section,
  }) async {
    final root = await _rootDir();
    final dir = Directory(
      '${root.path}/Semester_$semesterNumber/'
      '${sanitize(subjectName)}/$section',
    );
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies [source] into [destinationDir] as [fileName], overwriting any
  /// existing file of that name (used for "one syllabus per subject" —
  /// re-uploading replaces the old file). Returns the stored file's path.
  Future<String> copyInto({
    required File source,
    required Directory destinationDir,
    required String fileName,
  }) async {
    final destPath = '${destinationDir.path}/$fileName';
    final existing = File(destPath);
    if (await existing.exists()) {
      await existing.delete();
    }
    final copied = await source.copy(destPath);
    return copied.path;
  }

  /// Copies [source] into [destinationDir], appending " (1)", " (2)",
  /// etc. to [fileName] if one already exists — used by features like
  /// Resources where many files can share a name and none should
  /// silently overwrite another, unlike Syllabus's intentional
  /// overwrite-on-replace behavior above.
  Future<String> copyWithUniqueName({
    required File source,
    required Directory destinationDir,
    required String fileName,
  }) async {
    final dotIndex = fileName.lastIndexOf('.');
    final ext = dotIndex == -1 ? '' : fileName.substring(dotIndex);
    final base = dotIndex == -1 ? fileName : fileName.substring(0, dotIndex);

    var candidate = fileName;
    var counter = 1;
    while (await File('${destinationDir.path}/$candidate').exists()) {
      candidate = '$base ($counter)$ext';
      counter++;
    }

    final copied = await source.copy('${destinationDir.path}/$candidate');
    return copied.path;
  }

  Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
  Future<void> deleteSubjectDir({
  required int semesterNumber,
  required String subjectName,
}) async {
  final root = await _rootDir();

  final dir = Directory(
    '${root.path}/Semester_$semesterNumber/${sanitize(subjectName)}',
  );

  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
}
}
