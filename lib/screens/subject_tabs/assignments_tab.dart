import 'package:flutter/material.dart';

import '../../core/models/assignment.dart';
import '../../core/models/enums.dart';
import '../../core/models/subject.dart';
import '../../core/services/assignment_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/create_assignment_sheet.dart';
import '../../widgets/placeholder_view.dart';

/// Assignment Manager tab (Phase 14): upload a PDF, set a deadline,
/// track Pending/Submitted/Overdue. Deliberately simple, matching the
/// plan's own "Simple." note for this phase.
class AssignmentsTab extends StatelessWidget {
  const AssignmentsTab({super.key, required this.subject});

  final Subject subject;

  Future<void> _confirmDelete(BuildContext context, Assignment assignment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('This removes "${assignment.title}" and its PDF from local storage.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await AssignmentService.instance.delete(assignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Assignment>>(
      stream: AssignmentService.instance.watchForSubject(subject.id),
      builder: (context, snapshot) {
        final assignments = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: assignments.isEmpty
                  ? const PlaceholderView(
                      icon: Icons.assignment_outlined,
                      title: 'No assignments yet',
                      subtitle:
                          'Upload an assignment PDF and set a deadline — '
                          "you'll see it here with its status.",
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: assignments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final a = assignments[i];
                        return _AssignmentCard(
                          assignment: a,
                          onToggleStatus: () => AssignmentService.instance.setStatus(
                            a,
                            a.status == AssignmentStatus.pending
                                ? AssignmentStatus.submitted
                                : AssignmentStatus.pending,
                          ),
                          onDelete: () => _confirmDelete(context, a),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => CreateAssignmentSheet.show(context, subject),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Assignment'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({
    required this.assignment,
    required this.onToggleStatus,
    required this.onDelete,
  });

  final Assignment assignment;
  final VoidCallback onToggleStatus;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitted = assignment.status == AssignmentStatus.submitted;
    final isOverdue = assignment.isOverdue;

    final Color chipColor;
    final String chipLabel;
    if (isSubmitted) {
      chipColor = Colors.green;
      chipLabel = 'Submitted';
    } else if (isOverdue) {
      chipColor = theme.colorScheme.error;
      chipLabel = 'Overdue';
    } else {
      chipColor = theme.colorScheme.primary;
      chipLabel = 'Pending';
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: const Icon(Icons.picture_as_pdf_outlined),
        ),
        title: Text(assignment.title),
        subtitle: Text('Due ${AppDateUtils.short(assignment.deadline)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ActionChip(
              label: Text(chipLabel),
              labelStyle: TextStyle(color: chipColor, fontWeight: FontWeight.w600),
              backgroundColor: chipColor.withValues(alpha: 0.12),
              side: BorderSide.none,
              onPressed: onToggleStatus,
            ),
            IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}