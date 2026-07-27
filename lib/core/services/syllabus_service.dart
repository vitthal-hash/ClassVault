import 'dart:io';

import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/subject.dart';
import '../models/syllabus.dart';
import 'file_storage_service.dart';
import 'semester_service.dart';
import 'text_extraction_service.dart';

class SyllabusService {
  SyllabusService._();
  static final SyllabusService instance = SyllabusService._();

  Isar get _db => IsarService.instance.db;

  Stream<Syllabus?> watchForSubject(int subjectId) {
    return _db.syllabus
        .filter()
        .subjectIdEqualTo(subjectId)
        .watch(fireImmediately: true)
        .map((list) => list.isEmpty ? null : list.first);
  }

  Future<Syllabus?> getForSubject(int subjectId) {
    return _db.syllabus.filter().subjectIdEqualTo(subjectId).findFirst();
  }

  /// Copies [pickedFile] into
  /// `AcademicAssistant/Semester_X/SubjectName/Syllabus/Syllabus.pdf`,
  /// extracts its text once, and upserts the single Syllabus row for
  /// this subject (re-uploading replaces the old file + text, per the
  /// unique index on `subjectId`).
  Future<Syllabus> upload({
    required Subject subject,
    required File pickedFile,
  }) async {
    final semester = await SemesterService.instance.getById(subject.semesterId);
    final semesterNumber = semester?.semesterNumber ?? 0;

    final dir = await FileStorageService.instance.subjectSectionDir(
      semesterNumber: semesterNumber,
      subjectName: subject.name,
      section: 'Syllabus',
    );

    final storedPath = await FileStorageService.instance.copyInto(
      source: pickedFile,
      destinationDir: dir,
      fileName: 'Syllabus.pdf',
    );

    final text =
        await TextExtractionService.instance.extractFromPdf(File(storedPath));

    final existing = await getForSubject(subject.id);
    final syllabus = (existing ?? Syllabus())
      ..subjectId = subject.id
      ..fileName = 'Syllabus.pdf'
      ..filePath = storedPath
      ..extractedText = text
      ..uploadedAt = DateTime.now();

    await _db.writeTxn(() async {
      await _db.syllabus.put(syllabus);
    });

    return syllabus;
  }

  Future<void> delete(Syllabus syllabus) async {
    await FileStorageService.instance.deleteIfExists(syllabus.filePath);
    await _db.writeTxn(() async {
      await _db.syllabus.delete(syllabus.id);
    });
  }
}
