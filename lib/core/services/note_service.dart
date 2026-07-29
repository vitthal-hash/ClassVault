import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/note.dart';
import 'reminder_service.dart';

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

  Future<Note?> getById(int id) => _db.notes.get(id);

  Future<Note> create({
    required int subjectId,
    String? title,
    required String body,
    bool remindMe = false,
  }) async {
    final now = DateTime.now();
    final note = Note()
      ..subjectId = subjectId
      ..title = _cleanTitle(title)
      ..body = body
      ..remindMe = remindMe
      ..createdAt = now
      ..updatedAt = now;

    await _db.writeTxn(() async {
      await _db.notes.put(note);
    });
    if (remindMe) {
      await ReminderService.instance.scheduleNoteReminders(note);
    }
    return note;
  }

  /// [remindMe] is optional so screens that don't touch the toggle
  /// (there aren't any today, but future ones might) can keep calling
  /// `update` without needing to know the note's current value.
  Future<void> update(
    Note note, {
    String? title,
    required String body,
    bool? remindMe,
  }) async {
    note.title = _cleanTitle(title);
    note.body = body;
    if (remindMe != null) note.remindMe = remindMe;
    note.updatedAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.notes.put(note);
    });
    // The next lecture may have changed (edit could follow a toggle),
    // so always re-derive rather than trust what was scheduled before.
    if (note.remindMe) {
      await ReminderService.instance.scheduleNoteReminders(note);
    } else {
      await ReminderService.instance.cancelNoteReminders(note.id);
    }
  }

  /// Flips just the reminder toggle without touching title/body —
  /// used by the switch in the note editor so toggling doesn't require
  /// re-typing anything.
  Future<void> setRemindMe(Note note, bool value) async {
    note.remindMe = value;
    await _db.writeTxn(() async {
      await _db.notes.put(note);
    });
    if (value) {
      await ReminderService.instance.scheduleNoteReminders(note);
    } else {
      await ReminderService.instance.cancelNoteReminders(note.id);
    }
  }

  Future<void> delete(Note note) async {
    await ReminderService.instance.cancelNoteReminders(note.id);
    await _db.writeTxn(() async {
      await _db.notes.delete(note.id);
    });
  }

  String? _cleanTitle(String? title) {
    final trimmed = title?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}