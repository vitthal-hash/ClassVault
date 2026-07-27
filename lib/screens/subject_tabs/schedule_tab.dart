import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/subject.dart';
import '../../core/models/timetable_entry.dart';
import '../../core/services/timetable_service.dart';
import '../../utils/constants.dart';
import '../../widgets/placeholder_view.dart';
import '../../widgets/timetable_entry_form_sheet.dart';
import '../../widgets/timetable_entry_tile.dart';

/// Theory/Lab/Tutorial tab (Phase 4): every TimetableEntry for this
/// subject whose sessionType matches, sorted by day then time. A wrong
/// day/time can now be fixed directly — tap a slot to edit it, or use
/// "Add slot" for one the timetable upload missed or a one-off makeup
/// class — rather than only being fixable by re-uploading the whole
/// timetable.
class ScheduleTab extends StatelessWidget {
  const ScheduleTab({super.key, required this.subject, required this.sessionType});

  final Subject subject;
  final SessionType sessionType;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TimetableEntry>>(
      stream: TimetableService.instance.watchForSubject(subject.id),
      builder: (context, snapshot) {
        final entries = (snapshot.data ?? [])
            .where((e) => e.sessionType == sessionType)
            .toList();

        return Column(
          children: [
            Expanded(
              child: entries.isEmpty
                  ? PlaceholderView(
                      icon: sessionType.workspaceIcon,
                      title: 'No ${sessionType.label.toLowerCase()} slots yet',
                      subtitle:
                          'Slots created from a timetable upload show up '
                          'here — or add one manually below.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final entry = entries[i];
                        return TimetableEntryTile(
                          entry: entry,
                          onEdit: () => TimetableEntryFormSheet.showEdit(
                            context,
                            entry: entry,
                          ),
                          onDelete: () => TimetableService.instance.delete(entry),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => TimetableEntryFormSheet.showCreate(
                    context,
                    semesterId: subject.semesterId,
                    subjectId: subject.id,
                    sessionType: sessionType,
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text('Add ${sessionType.label} Slot'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

extension SessionTypeWorkspaceIcon on SessionType {
  IconData get workspaceIcon {
    switch (this) {
      case SessionType.theory:
        return SubjectSection.theory.icon;
      case SessionType.lab:
        return SubjectSection.lab.icon;
      case SessionType.tutorial:
        return SubjectSection.tutorial.icon;
    }
  }
}