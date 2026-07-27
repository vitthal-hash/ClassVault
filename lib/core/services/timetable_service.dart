import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/enums.dart';
import '../models/timetable_entry.dart';
import '../parsing/timetable_parser.dart';
import 'subject_service.dart';
import 'teacher_service.dart';

class TimetableService {
  TimetableService._();
  static final TimetableService instance = TimetableService._();

  Isar get _db => IsarService.instance.db;

  /// Saves reviewed rows: dedupes/creates Subjects and Teachers, then
  /// writes one TimetableEntry per row. Only rows that pass
  /// `ParsedTimetableRow.isComplete` should reach this point — the
  /// review screen is responsible for that.
  Future<int> commitRows({
    required List<ParsedTimetableRow> rows,
    required int semesterId,
  }) async {
    var created = 0;

    for (final row in rows) {
      if (!row.isComplete) continue;

      final subject = await SubjectService.instance.getOrCreate(
        name: row.subjectName,
        semesterId: semesterId,
      );

      int? teacherId;
      if (row.teacherName != null && row.teacherName!.trim().isNotEmpty) {
        final teacher = await TeacherService.instance.getOrCreate(row.teacherName!);
        teacherId = teacher.id;
      }

      final entry = TimetableEntry()
        ..semesterId = semesterId
        ..subjectId = subject.id
        ..teacherId = teacherId
        ..day = row.day!
        ..startMinutes = row.startMinutes!
        ..endMinutes = row.endMinutes!
        ..sessionType = row.sessionType
        ..room = row.room;

      await _db.writeTxn(() async {
        await _db.timetableEntrys.put(entry);
      });
      created++;
    }

    return created;
  }

  Stream<List<TimetableEntry>> watchForSemester(int semesterId) {
    return _db.timetableEntrys
        .filter()
        .semesterIdEqualTo(semesterId)
        .watch(fireImmediately: true)
        .map((list) => list
          ..sort((a, b) {
            final dayCompare = a.day.index.compareTo(b.day.index);
            if (dayCompare != 0) return dayCompare;
            return a.startMinutes.compareTo(b.startMinutes);
          }));
  }

  /// Used by the Subject Workspace (Phase 4) Theory/Lab/Tutorial tabs —
  /// every slot for one subject, across all session types. The tab
  /// itself filters down to the SessionType it renders.
  Stream<List<TimetableEntry>> watchForSubject(int subjectId) {
    return _db.timetableEntrys
        .filter()
        .subjectIdEqualTo(subjectId)
        .watch(fireImmediately: true)
        .map((list) => list
          ..sort((a, b) {
            final dayCompare = a.day.index.compareTo(b.day.index);
            if (dayCompare != 0) return dayCompare;
            return a.startMinutes.compareTo(b.startMinutes);
          }));
  }

  /// Used by Phase 8 (Smart Subject Detection): "what subject/session is
  /// scheduled right now for this semester?"
  Future<TimetableEntry?> findSlotAt({
    required int semesterId,
    required Weekday day,
    required int minutesSinceMidnight,
  }) {
    return _db.timetableEntrys
        .filter()
        .semesterIdEqualTo(semesterId)
        .dayEqualTo(day)
        .startMinutesLessThan(minutesSinceMidnight, include: true)
        .endMinutesGreaterThan(minutesSinceMidnight, include: true)
        .findFirst();
  }

  /// Also Phase 8: when nothing is scheduled *right now* and the person
  /// picks a subject manually, checks whether this time-of-day matches
  /// any of that subject's Lab slots on ANY day — the plan's "If Lab
  /// timing, store DBMS -> Lab. Otherwise Theory." fallback. Ignores the
  /// day on purpose, since at this point there's no matching day to
  /// begin with; it's purely "does 9 PM look like a Lab time for DBMS?".
  Future<bool> hasLabAtTimeOfDay({
    required int subjectId,
    required int minutesSinceMidnight,
  }) async {
    final match = await _db.timetableEntrys
        .filter()
        .subjectIdEqualTo(subjectId)
        .sessionTypeEqualTo(SessionType.lab)
        .startMinutesLessThan(minutesSinceMidnight, include: true)
        .endMinutesGreaterThan(minutesSinceMidnight, include: true)
        .findFirst();
    return match != null;
  }

  /// Fixes a slot's day, time, session type, teacher, or room after the
  /// fact — e.g. the timetable upload's OCR got a time slightly wrong,
  /// or the person just wants to correct something manually. Unlike
  /// `commitRows`, this doesn't touch Subject at all: moving a slot
  /// between sections/times never changes which subject it belongs to.
  Future<void> update(
    TimetableEntry entry, {
    required Weekday day,
    required int startMinutes,
    required int endMinutes,
    required SessionType sessionType,
    int? teacherId,
    String? room,
  }) async {
    entry.day = day;
    entry.startMinutes = startMinutes;
    entry.endMinutes = endMinutes;
    entry.sessionType = sessionType;
    entry.teacherId = teacherId;
    entry.room = (room == null || room.trim().isEmpty) ? null : room.trim();

    await _db.writeTxn(() async {
      await _db.timetableEntrys.put(entry);
    });
  }

  /// Manually adds a slot outside the timetable-upload flow — e.g. a
  /// one-off makeup class, or fixing a subject the OCR missed entirely.
  Future<TimetableEntry> create({
    required int semesterId,
    required int subjectId,
    required Weekday day,
    required int startMinutes,
    required int endMinutes,
    required SessionType sessionType,
    int? teacherId,
    String? room,
  }) async {
    final entry = TimetableEntry()
      ..semesterId = semesterId
      ..subjectId = subjectId
      ..day = day
      ..startMinutes = startMinutes
      ..endMinutes = endMinutes
      ..sessionType = sessionType
      ..teacherId = teacherId
      ..room = (room == null || room.trim().isEmpty) ? null : room.trim();

    await _db.writeTxn(() async {
      await _db.timetableEntrys.put(entry);
    });
    return entry;
  }

  Future<void> delete(TimetableEntry entry) async {
    await _db.writeTxn(() async {
      await _db.timetableEntrys.delete(entry.id);
    });
  }
}