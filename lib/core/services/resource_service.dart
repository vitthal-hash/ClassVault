import 'dart:io';

import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/enums.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import 'file_storage_service.dart';
import 'semester_service.dart';
import 'text_extraction_service.dart';

class ResourceService {
  ResourceService._();
  static final ResourceService instance = ResourceService._();

  Isar get _db => IsarService.instance.db;

  Stream<List<Resource>> watchForSubject(int subjectId) {
    return _db.resources
        .filter()
        .subjectIdEqualTo(subjectId)
        .watch(fireImmediately: true)
        .map((list) => list..sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt)));
  }

  /// Uploads every file in [pickedFiles] whose extension maps to a known
  /// [ResourceType] (PDF/PPT/Word/Image); anything else is skipped and
  /// its original name returned in `skipped` so the screen can tell the
  /// person which files didn't make it in.
  Future<ResourceUploadResult> uploadAll({
    required Subject subject,
    required List<File> pickedFiles,
  }) async {
    final uploaded = <Resource>[];
    final skipped = <String>[];

    final semester = await SemesterService.instance.getById(subject.semesterId);
    final semesterNumber = semester?.semesterNumber ?? 0;

    for (final file in pickedFiles) {
      final originalName = file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last
          : file.path;
      final type = ResourceTypeX.fromExtension(originalName);
      if (type == null) {
        skipped.add(originalName);
        continue;
      }

      final dir = await FileStorageService.instance.subjectSectionDir(
        semesterNumber: semesterNumber,
        subjectName: subject.name,
        section: 'Resources/${type.folderName}',
      );

      final storedPath = await FileStorageService.instance.copyWithUniqueName(
        source: file,
        destinationDir: dir,
        fileName: originalName,
      );
      final storedName = storedPath.split('/').last;

      String? text;
      if (type == ResourceType.pdf) {
        text = await TextExtractionService.instance.extractFromPdf(File(storedPath));
      } else if (type == ResourceType.image) {
        text = await TextExtractionService.instance.extractFromImage(File(storedPath));
      }

      final resource = Resource()
        ..subjectId = subject.id
        ..name = storedName
        ..filePath = storedPath
        ..type = type
        ..extractedText = text;

      await _db.writeTxn(() async {
        await _db.resources.put(resource);
      });
      uploaded.add(resource);
    }

    return ResourceUploadResult(uploaded: uploaded, skipped: skipped);
  }

  Future<void> delete(Resource resource) async {
    await FileStorageService.instance.deleteIfExists(resource.filePath);
    await _db.writeTxn(() async {
      await _db.resources.delete(resource.id);
    });
  }
}

class ResourceUploadResult {
  ResourceUploadResult({required this.uploaded, required this.skipped});

  final List<Resource> uploaded;

  /// Original file names that had no recognized PDF/PPT/Word/Image
  /// extension, and so were not copied or saved.
  final List<String> skipped;
}
