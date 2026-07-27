import 'package:flutter/material.dart';

import '../core/models/enums.dart';
import '../core/models/teacher.dart';
import '../core/models/timetable_entry.dart';
import '../core/services/teacher_service.dart';
import '../core/services/timetable_service.dart';

/// Add/edit sheet for one [TimetableEntry] — the fix for "I added the
/// wrong day or time and can't change it afterward." Used two ways:
/// - `TimetableEntryFormSheet.showEdit(context, entry: ...)` from a tap
///   on an existing slot in a Schedule tab.
/// - `TimetableEntryFormSheet.showCreate(context, subject: ..., semesterId:
///   ..., sessionType: ...)` from that same tab's "Add slot" button, for
///   a slot the timetable upload missed or a one-off makeup class.
class TimetableEntryFormSheet extends StatefulWidget {
  const TimetableEntryFormSheet({
    super.key,
    required this.semesterId,
    required this.subjectId,
    required this.sessionType,
    this.entry,
  });

  final int semesterId;
  final int subjectId;
  final SessionType sessionType;

  /// Null when adding a new slot; the existing entry when editing.
  final TimetableEntry? entry;

  static Future<void> showEdit(
    BuildContext context, {
    required TimetableEntry entry,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TimetableEntryFormSheet(
        semesterId: entry.semesterId,
        subjectId: entry.subjectId,
        sessionType: entry.sessionType,
        entry: entry,
      ),
    );
  }

  static Future<void> showCreate(
    BuildContext context, {
    required int semesterId,
    required int subjectId,
    required SessionType sessionType,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TimetableEntryFormSheet(
        semesterId: semesterId,
        subjectId: subjectId,
        sessionType: sessionType,
      ),
    );
  }

  @override
  State<TimetableEntryFormSheet> createState() =>
      _TimetableEntryFormSheetState();
}

class _TimetableEntryFormSheetState extends State<TimetableEntryFormSheet> {
  late Weekday _day;
  late SessionType _sessionType;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late final TextEditingController _roomController;
  late final TextEditingController _teacherController;

  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _day = entry?.day ?? Weekday.monday;
    _sessionType = entry?.sessionType ?? widget.sessionType;
    _startTime = entry == null
        ? const TimeOfDay(hour: 9, minute: 0)
        : _toTimeOfDay(entry.startMinutes);
    _endTime = entry == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : _toTimeOfDay(entry.endMinutes);
    _roomController = TextEditingController(text: entry?.room ?? '');
    _teacherController = TextEditingController();

    if (entry?.teacherId != null) {
      TeacherService.instance.getById(entry!.teacherId!).then((teacher) {
        if (mounted && teacher != null) {
          setState(() => _teacherController.text = teacher.name);
        }
      });
    }
  }

  TimeOfDay _toTimeOfDay(int minutes) =>
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

  int _toMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    final startMinutes = _toMinutes(_startTime);
    final endMinutes = _toMinutes(_endTime);
    if (endMinutes <= startMinutes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      int? teacherId;
      final teacherName = _teacherController.text.trim();
      if (teacherName.isNotEmpty) {
        final teacher = await TeacherService.instance.getOrCreate(teacherName);
        teacherId = teacher.id;
      }

      if (_isEditing) {
        await TimetableService.instance.update(
          widget.entry!,
          day: _day,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          sessionType: _sessionType,
          teacherId: teacherId,
          room: _roomController.text,
        );
      } else {
        await TimetableService.instance.create(
          semesterId: widget.semesterId,
          subjectId: widget.subjectId,
          day: _day,
          startMinutes: startMinutes,
          endMinutes: endMinutes,
          sessionType: _sessionType,
          teacherId: teacherId,
          room: _roomController.text,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    _teacherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _isEditing ? 'Edit Slot' : 'Add Slot',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Weekday>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: [
              for (final day in Weekday.values)
                DropdownMenuItem(value: day, child: Text(day.label)),
            ],
            onChanged: (value) => setState(() => _day = value ?? _day),
          ),
          const SizedBox(height: 14),
          SegmentedButton<SessionType>(
            segments: [
              for (final type in SessionType.values)
                ButtonSegment(value: type, label: Text(type.label)),
            ],
            selected: {_sessionType},
            onSelectionChanged: (selection) =>
                setState(() => _sessionType = selection.first),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: true),
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_startTime.format(context)),
                ),
              ),
              const SizedBox(width: 12),
              const Text('to'),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(isStart: false),
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text(_endTime.format(context)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _teacherController,
            decoration: const InputDecoration(labelText: 'Teacher (optional)'),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _roomController,
            decoration: const InputDecoration(labelText: 'Room (optional)'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}