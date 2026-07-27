import 'package:flutter/material.dart';

import '../core/models/enums.dart';
import '../core/parsing/timetable_parser.dart';

class TimetableRowEditSheet extends StatefulWidget {
  const TimetableRowEditSheet({super.key, required this.row});

  final ParsedTimetableRow row;

  static Future<ParsedTimetableRow?> show(
    BuildContext context,
    ParsedTimetableRow row,
  ) {
    return showModalBottomSheet<ParsedTimetableRow>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TimetableRowEditSheet(row: row),
    );
  }

  @override
  State<TimetableRowEditSheet> createState() => _TimetableRowEditSheetState();
}

class _TimetableRowEditSheetState extends State<TimetableRowEditSheet> {
  late final _subjectController =
      TextEditingController(text: widget.row.subjectName);
  late final _teacherController =
      TextEditingController(text: widget.row.teacherName ?? '');
  late final _roomController = TextEditingController(text: widget.row.room ?? '');

  late Weekday? _day = widget.row.day;
  late int? _start = widget.row.startMinutes;
  late int? _end = widget.row.endMinutes;
  late SessionType _sessionType = widget.row.sessionType;

  @override
  void dispose() {
    _subjectController.dispose();
    _teacherController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickTime(bool isStart) async {
    final initial = TimeOfDay(
      hour: (isStart ? _start : _end) != null
          ? (isStart ? _start! : _end!) ~/ 60
          : 9,
      minute: (isStart ? _start : _end) != null
          ? (isStart ? _start! : _end!) % 60
          : 0,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      final minutes = picked.hour * 60 + picked.minute;
      if (isStart) {
        _start = minutes;
      } else {
        _end = minutes;
      }
    });
  }

  String _fmt(int? minutes) {
    if (minutes == null) return 'Set time';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  void _save() {
    if (_subjectController.text.trim().isEmpty || _day == null || _start == null || _end == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject, day, and both times are required')),
      );
      return;
    }
    final updated = ParsedTimetableRow(
      day: _day,
      startMinutes: _start,
      endMinutes: _end,
      subjectName: _subjectController.text.trim(),
      sessionType: _sessionType,
      teacherName: _teacherController.text.trim().isEmpty
          ? null
          : _teacherController.text.trim(),
      room: _roomController.text.trim().isEmpty ? null : _roomController.text.trim(),
      sourceLine: widget.row.sourceLine,
    );
    Navigator.of(context).pop(updated);
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
          Text('Edit Timetable Row',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'From: "${widget.row.sourceLine}"',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _subjectController,
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Weekday>(
            initialValue: _day,
            decoration: const InputDecoration(labelText: 'Day'),
            items: Weekday.values
                .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
                .toList(),
            onChanged: (v) => setState(() => _day = v),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(true),
                  child: Text('Start: ${_fmt(_start)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _pickTime(false),
                  child: Text('End: ${_fmt(_end)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedButton<SessionType>(
            segments: SessionType.values
                .map((s) => ButtonSegment(value: s, label: Text(s.label)))
                .toList(),
            selected: {_sessionType},
            onSelectionChanged: (s) => setState(() => _sessionType = s.first),
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
          const SizedBox(height: 22),
          ElevatedButton(onPressed: _save, child: const Text('Save Row')),
        ],
      ),
    );
  }
}
