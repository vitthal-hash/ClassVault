import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/enums.dart';
import '../models/lecture.dart';
import '../models/subject.dart';
import 'file_storage_service.dart';
import 'semester_service.dart';

/// Phase 7 — Lecture Upload: "DBMS -> Theory -> + -> Camera / Gallery".
///
/// Stores the photo under `Subject/<Theory|Lab|Tutorial>/Images/` (the
/// plan's own folder layout, which also reserves a sibling `OCR/`
/// folder for Phase 9) and writes one `Lecture` row with an
/// auto-generated ID like `DBMS_T_005`.
class LectureService {
  LectureService._();
  static final LectureService instance = LectureService._();

  final ImagePicker _picker = ImagePicker();

  Isar get _db => IsarService.instance.db;

  Stream<List<Lecture>> watchForSection({
    required int subjectId,
    required SessionType sessionType,
  }) {
    return _db.lectures
        .filter()
        .subjectIdEqualTo(subjectId)
        .sessionTypeEqualTo(sessionType)
        .watch(fireImmediately: true)
        .map((list) => list..sort((a, b) => b.capturedAt.compareTo(a.capturedAt)));
  }

  /// Opens the camera, then stores the result. Returns null if the user
  /// backs out without taking a photo.
  Future<Lecture?> captureFromCamera({
    required Subject subject,
    required SessionType sessionType,
  }) async {
    final picked = await pickImage(ImageSource.camera);
    if (picked == null) return null;
    return saveCapturedImage(
      subject: subject,
      sessionType: sessionType,
      image: picked,
    );
  }

  /// Opens the gallery. Returns null if the user cancels.
  Future<Lecture?> pickFromGallery({
    required Subject subject,
    required SessionType sessionType,
  }) async {
    final picked = await pickImage(ImageSource.gallery);
    if (picked == null) return null;
    return saveCapturedImage(
      subject: subject,
      sessionType: sessionType,
      image: picked,
    );
  }

  /// Camera/gallery capture with no subject/session attached yet — used
  /// by Phase 8's quick-capture flow, which picks the photo first and
  /// only decides where it belongs afterward (via smart detection or,
  /// failing that, asking the person). Returns null if cancelled.
  Future<XFile?> pickImage(ImageSource source) {
    return _picker.pickImage(source: source, imageQuality: 90);
  }

  /// Stores an already-picked image against a known subject/session.
  /// Public (rather than the private `_store` it replaces) so both the
  /// direct capture methods above and Phase 8's quick-capture flow can
  /// call it once the subject/session is known.
  Future<Lecture> saveCapturedImage({
    required Subject subject,
    required SessionType sessionType,
    required XFile image,
  }) => _store(subject: subject, sessionType: sessionType, picked: image);

  Future<Lecture> _store({
    required Subject subject,
    required SessionType sessionType,
    required XFile picked,
  }) async {
    final semester = await SemesterService.instance.getById(subject.semesterId);
    final semesterNumber = semester?.semesterNumber ?? 0;

    final dir = await FileStorageService.instance.subjectSectionDir(
      semesterNumber: semesterNumber,
      subjectName: subject.name,
      section: '${sessionType.label}/Images',
    );

    final code = await _nextLectureCode(
      subject: subject,
      sessionType: sessionType,
    );
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';

    final storedPath = await FileStorageService.instance.copyWithUniqueName(
      source: File(picked.path),
      destinationDir: dir,
      fileName: '$code.$ext',
    );

    final now = DateTime.now();
    final lecture = Lecture()
      ..subjectId = subject.id
      ..sessionType = sessionType
      ..lectureCode = code
      ..imagePath = storedPath
      ..capturedAt = now
      ..createdAt = now;

    await _db.writeTxn(() async {
      await _db.lectures.put(lecture);
    });
    return lecture;
  }

  /// `<SUBJECT_CODE>_<SESSION_INITIAL>_<count+1 padded to 3 digits>`,
  /// e.g. `DBMS_T_005`. Falls back to a sanitized subject name when no
  /// short code has been set via the "Edit subject code" sheet.
  Future<String> _nextLectureCode({
    required Subject subject,
    required SessionType sessionType,
  }) async {
    final prefix = _codePrefix(subject);

    final existingCount = await _db.lectures
        .filter()
        .subjectIdEqualTo(subject.id)
        .sessionTypeEqualTo(sessionType)
        .count();

    final number = (existingCount + 1).toString().padLeft(3, '0');
    return '${prefix}_${sessionType.codeInitial}_$number';
  }

  String _codePrefix(Subject subject) {
    final code = subject.code?.trim();
    if (code != null && code.isNotEmpty) {
      return code.toUpperCase().replaceAll(RegExp(r'\s+'), '');
    }
    // No code set yet — fall back to the subject name, uppercased and
    // stripped of spaces, so IDs are still readable rather than blank.
    return subject.name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  /// Phase 9 (OCR): commits the person's reviewed/edited text. Always
  /// writes a value — even an empty string — so the review screen can
  /// tell "not OCR'd yet" (`ocrText == null`) apart from "OCR'd once,
  /// edited down to nothing" (`ocrText == ''`) and never re-runs OCR
  /// on an already-reviewed lecture ("Never OCR again" per the plan).
  Future<void> updateOcrText(Lecture lecture, String text) async {
    lecture.ocrText = text;
    await _db.writeTxn(() async {
      await _db.lectures.put(lecture);
    });
  }

  /// Phase 15 (Revision): every starred lecture in one subject, regardless
  /// of Theory/Lab/Tutorial section — the Revision folder cuts across
  /// sections since it's about what to review, not where it was taught.
  Future<List<Lecture>> starredForSubject(int subjectId) {
    return _db.lectures
        .filter()
        .subjectIdEqualTo(subjectId)
        .isStarredEqualTo(true)
        .findAll();
  }

  Future<void> toggleStar(Lecture lecture) async {
    lecture.isStarred = !lecture.isStarred;
    await _db.writeTxn(() async {
      await _db.lectures.put(lecture);
    });
  }

  Future<void> delete(Lecture lecture) async {
    await FileStorageService.instance.deleteIfExists(lecture.imagePath);
    await _db.writeTxn(() async {
      await _db.lectures.delete(lecture.id);
    });
  }
}
