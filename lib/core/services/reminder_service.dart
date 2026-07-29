import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../database/isar_service.dart';
import '../models/assignment.dart';
import '../models/enums.dart';
import '../models/note.dart';
import 'assignment_service.dart';
import 'note_service.dart';
import 'subject_service.dart';
import 'timetable_service.dart';
/// Phase 17 (Reminders) — schedules and cancels every local
/// notification in the app:
///
/// - **Notes**: when a note's `remindMe` toggle is on, one recurring
///   weekly notification per distinct lecture-day of that note's
///   subject, firing the evening *before* each occurrence.
/// - **Assignments**: two one-shot notifications per assignment — the
///   evening before the deadline, and the morning of the deadline —
///   each with "I'll do it" (snooze ~4h, re-notify) and "Done" (mark
///   submitted, cancel the rest) actions.
///
/// Notification IDs are deterministic so they can be cancelled without
/// keeping a separate id column in Isar:
///   - Notes:       100000 + noteId * 10 + dayIndex   (dayIndex 0-6)
///   - Assignments: 200000 + assignmentId * 10 + slot (0 = day-before,
///                  1 = on-date, 2 = snooze follow-up)
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const int _noteBaseId = 100000;
  static const int _assignmentBaseId = 200000;
  static const String _assignmentCategory = 'assignmentActions';
  static const int _reminderHour = 18; // 6 PM for "day before" nudges
  static const int _dueDateHour = 9; // 9 AM for "due today" nudges

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Set from main.dart if the app wants to react to a plain (no
  /// action) tap on a note reminder, e.g. to open that note. Kept as a
  /// callback rather than a hard dependency so this service doesn't
  /// need to know about navigation/UI.
  static void Function(int noteId)? onNoteReminderTapped;

  bool _initialized = false;

  /// Call once from main() before runApp. Safe to call more than once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      // Fall back to UTC rather than crash startup over a timezone
      // lookup failing on some device — reminders will just fire
      // relative to UTC until the person reopens the app.
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    await _registerAssignmentActionCategory();
    await _requestPermissions();
  }

  Future<void> _registerAssignmentActionCategory() async {
    // iOS/macOS need the action buttons declared as a "category" up
    // front; Android attaches actions per-notification instead (done
    // in _assignmentDetails below), so this is a no-op there.
    if (!Platform.isIOS && !Platform.isMacOS) return;
    final category = DarwinNotificationCategory(
      _assignmentCategory,
      actions: [
        DarwinNotificationAction.plain('snooze', "I'll do it"),
        DarwinNotificationAction.plain('done', 'Done'),
      ],
    );
    final darwin = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await darwin?.initialize(
      DarwinInitializationSettings(notificationCategories: [category]),
    );
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
    } else if (Platform.isMacOS) {
      final macos = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      await macos?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  // ---------------------------------------------------------------
  // Notes
  // ---------------------------------------------------------------

  /// Re-derives everything from scratch: cancels whatever was
  /// scheduled for this note, then — if `remindMe` is on and the
  /// subject actually has timetable slots — schedules one recurring
  /// notification per distinct lecture weekday.
  Future<void> scheduleNoteReminders(Note note) async {
    await cancelNoteReminders(note.id);
    if (!note.remindMe) return;

    final entries = await TimetableService.instance.getForSubject(note.subjectId);
    if (entries.isEmpty) return; // nothing on the timetable to hang a reminder off

    final subject = await SubjectService.instance.getById(note.subjectId);
    final subjectName = subject?.name ?? 'your subject';
    final preview = (note.title?.trim().isNotEmpty ?? false)
        ? note.title!.trim()
        : note.body.split('\n').first;

    final distinctDays = entries.map((e) => e.day).toSet().toList();
    for (var i = 0; i < distinctDays.length && i < 7; i++) {
      final lectureDay = distinctDays[i];
      final reminderDay = Weekday.values[(lectureDay.index - 1 + 7) % 7];
      final scheduled = _nextInstanceOfWeekday(reminderDay, _reminderHour, 0);

      await _plugin.zonedSchedule(
        _noteBaseId + note.id * 10 + i,
        '$subjectName lecture tomorrow',
        preview,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'note_reminders',
            'Note reminders',
            channelDescription:
                'Reminders about notes the evening before a related lecture',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'note:${note.id}',
      );
    }
  }

  Future<void> cancelNoteReminders(int noteId) async {
    for (var i = 0; i < 7; i++) {
      await _plugin.cancel(_noteBaseId + noteId * 10 + i);
    }
  }

  /// Called by TimetableService whenever a slot for [subjectId] is
  /// added, edited, or removed. A note's reminder is derived from that
  /// subject's timetable (which weekday, what time), so any change
  /// there can make an already-scheduled reminder point at the wrong
  /// day — this re-derives every remind-me'd note for the subject from
  /// scratch rather than trying to patch the old schedule in place.
  Future<void> rescheduleNoteRemindersForSubject(int subjectId) async {
    final notes = await NoteService.instance.getForSubject(subjectId);
    for (final note in notes) {
      if (note.remindMe) {
        await scheduleNoteReminders(note);
      }
    }
  }

  // ---------------------------------------------------------------
  // Assignments
  // ---------------------------------------------------------------

  /// Re-derives the day-before and on-date reminders from the
  /// assignment's current deadline. Any past-due slot (e.g. the
  /// "day before" time has already passed when this is called) is
  /// simply skipped rather than scheduled in the past.
  Future<void> scheduleAssignmentReminders(Assignment assignment) async {
    await cancelAssignmentReminders(assignment.id);
    if (assignment.status == AssignmentStatus.submitted) return;

    final subject = await SubjectService.instance.getById(assignment.subjectId);
    final subjectName = subject?.name ?? 'your subject';
    final deadline = assignment.deadline;

    final dayBefore = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day - 1,
      _reminderHour,
    );
    final onDate = tz.TZDateTime(
      tz.local,
      deadline.year,
      deadline.month,
      deadline.day,
      _dueDateHour,
    );
    final now = tz.TZDateTime.now(tz.local);

    if (dayBefore.isAfter(now)) {
      await _plugin.zonedSchedule(
        _assignmentBaseId + assignment.id * 10 + 0,
        '$subjectName assignment due tomorrow',
        assignment.title,
        dayBefore,
        _assignmentDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'assignment:${assignment.id}',
      );
    }
    if (onDate.isAfter(now)) {
      await _plugin.zonedSchedule(
        _assignmentBaseId + assignment.id * 10 + 1,
        '$subjectName assignment due today',
        assignment.title,
        onDate,
        _assignmentDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'assignment:${assignment.id}',
      );
    }
  }

  /// Fired from the "I'll do it" action — nags again a few hours
  /// later. Never schedules past the deadline; if there's no room left
  /// today it falls back to the next morning so it doesn't just vanish.
  Future<void> _scheduleAssignmentSnooze(Assignment assignment) async {
    final subject = await SubjectService.instance.getById(assignment.subjectId);
    final subjectName = subject?.name ?? 'your subject';
    final now = tz.TZDateTime.now(tz.local);

    var next = now.add(const Duration(hours: 4));
    final deadline = tz.TZDateTime.from(assignment.deadline, tz.local);
    if (next.isAfter(deadline)) {
      // Past the deadline already — one last nudge next morning rather
      // than silently dropping it.
      next = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, _dueDateHour);
    }

    await _plugin.zonedSchedule(
      _assignmentBaseId + assignment.id * 10 + 2,
      '$subjectName assignment — still pending',
      assignment.title,
      next,
      _assignmentDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'assignment:${assignment.id}',
    );
  }

  Future<void> cancelAssignmentReminders(int assignmentId) async {
    for (var slot = 0; slot < 3; slot++) {
      await _plugin.cancel(_assignmentBaseId + assignmentId * 10 + slot);
    }
  }

  NotificationDetails _assignmentDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'assignment_reminders',
        'Assignment reminders',
        channelDescription: 'Day-before and due-date assignment nudges',
        importance: Importance.high,
        actions: [
          AndroidNotificationAction('snooze', "I'll do it"),
          AndroidNotificationAction('done', 'Done'),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: _assignmentCategory),
      macOS: DarwinNotificationDetails(categoryIdentifier: _assignmentCategory),
    );
  }

  // ---------------------------------------------------------------
  // Response handling — runs in the foreground isolate for a live tap,
  // or in the background isolate (via notificationTapBackground below)
  // when the app was closed. Both paths funnel through here.
  // ---------------------------------------------------------------

  static Future<void> _handleResponse(NotificationResponse response) async {
    final payload = response.payload;
    if (payload == null) return;
    final parts = payload.split(':');
    if (parts.length != 2) return;
    final kind = parts[0];
    final id = int.tryParse(parts[1]);
    if (id == null) return;

    if (kind == 'assignment') {
      final assignment = await AssignmentService.instance.getById(id);
      if (assignment == null) return;

      if (response.actionId == 'done') {
        await AssignmentService.instance.setStatus(
          assignment,
          AssignmentStatus.submitted,
        );
      } else if (response.actionId == 'snooze') {
        await ReminderService.instance._scheduleAssignmentSnooze(assignment);
      }
      // A plain tap (actionId null) just opens the app on the
      // assignment's subject in most launchers by default; nothing
      // else to do here.
    } else if (kind == 'note') {
      if (response.actionId == null) {
        onNoteReminderTapped?.call(id);
      }
    }
  }

  tz.TZDateTime _nextInstanceOfWeekday(Weekday weekday, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    // Weekday.index is 0=Monday..6=Sunday; DateTime.weekday is 1=Monday..7=Sunday.
    while (scheduled.weekday != weekday.index + 1 || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

/// Must be a top-level (or static) function annotated with
/// `vm:entry-point`: flutter_local_notifications spins this up in its
/// own background isolate when a notification action is tapped while
/// the app is fully closed, so it can't reuse the main isolate's
/// already-open Isar instance — it has to open its own.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) async {
  if (!IsarService.instance.isReady) {
    await IsarService.instance.init();
  }
  await ReminderService._handleResponse(response);
}