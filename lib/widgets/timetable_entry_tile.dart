import 'package:flutter/material.dart';

import '../core/models/enums.dart';
import '../core/models/teacher.dart';
import '../core/models/timetable_entry.dart';
import '../core/services/teacher_service.dart';

/// One row in a subject's Theory/Lab/Tutorial schedule.
///
/// Teacher names are stored by id on TimetableEntry (a teacher can teach
/// several subjects/slots), so this tile resolves the name itself via a
/// small FutureBuilder rather than making every screen do that lookup.
class TimetableEntryTile extends StatelessWidget {
  const TimetableEntryTile({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
  });

  final TimetableEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        onTap: onEdit,
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.secondaryContainer,
          child: Text(
            entry.day.label.substring(0, 2),
            style: theme.textTheme.labelMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        title: Text('${entry.day.label} · ${entry.timeRangeLabel}'),
        subtitle: entry.teacherId == null
            ? (entry.room != null ? Text('Room ${entry.room}') : null)
            : FutureBuilder<Teacher?>(
                future: TeacherService.instance.getById(entry.teacherId!),
                builder: (context, snapshot) {
                  final teacher = snapshot.data;
                  final parts = <String>[
                    if (teacher != null) teacher.name,
                    if (entry.room != null) 'Room ${entry.room}',
                  ];
                  return Text(parts.isEmpty ? '—' : parts.join(' · '));
                },
              ),
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Remove slot',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
      ),
    );
  }
}