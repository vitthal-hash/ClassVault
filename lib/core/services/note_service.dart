import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/note.dart';

/// Quick Notes: a person's own free-form notes about a subject —
/// "what was taught in that lecture that day" and similar — separate
/// from the photo+OCR pipeline Lectures use.
class NoteService {
  NoteService._();
  static final NoteService instance = NoteService._();

  Isar get _db => IsarService.instance.db;

  Stream<List<Note>> watchForSubject(int subjectId) {
    return _db.notes
        .filter()
        .subjectIdEqualTo(subjectId)
        .watch(fireImmediately: true)
        .map((list) => list..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)));
  }

  Future<List<Note>> getForSubject(int subjectId) {
    return _db.notes.filter().subjectIdEqualTo(subjectId).findAll();
  }

  Future<Note> create({
    required int subjectId,
    String? title,
    required String body,
  }) async {
    final now = DateTime.now();
    final note = Note()
      ..subjectId = subjectId
      ..title = _cleanTitle(title)
      ..body = body
      ..createdAt = now
      ..updatedAt = now;

    await _db.writeTxn(() async {
      await _db.notes.put(note);
    });
    return note;
  }

  Future<void> update(Note note, {String? title, required String body}) async {
    note.title = _cleanTitle(title);
    note.body = body;
    note.updatedAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.notes.put(note);
    });
  }

  Future<void> delete(Note note) async {
    await _db.writeTxn(() async {
      await _db.notes.delete(note.id);
    });
  }

  String? _cleanTitle(String? title) {
    final trimmed = title?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}