import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/semester.dart';
import '../core/theme/app_tokens.dart';
import '../providers/semester_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/create_semester_sheet.dart';
import '../widgets/placeholder_view.dart';

class SemesterScreen extends StatelessWidget {
  const SemesterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final semesters = context.watch<SemesterProvider>().semesters;

    return Scaffold(
      appBar: AppBar(title: const Text('Semesters')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => CreateSemesterSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Semester'),
      ),
      body: semesters.isEmpty
          ? const PlaceholderView(
              icon: Icons.calendar_month_rounded,
              title: 'No semesters yet',
              subtitle:
                  'Tap "New Semester" below to create your first one — '
                  'name, number, start & end date.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxxl,
              ),
              itemCount: semesters.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) =>
                  _SemesterCard(semester: semesters[i]),
            ),
    );
  }
}

class _SemesterCard extends StatelessWidget {
  const _SemesterCard({required this.semester});

  final Semester semester;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.read<SemesterProvider>();
    final status = semester.isActive
        ? _StatusChip(
            label: 'Active',
            color: theme.colorScheme.primary,
            background: theme.colorScheme.primaryContainer,
          )
        : semester.hasEnded
            ? _StatusChip(
                label: 'Ended',
                color: theme.colorScheme.onSurfaceVariant,
                background: theme.colorScheme.surfaceContainerHighest,
              )
            : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: AppRadius.mdRadius,
              ),
              child: Center(
                child: Text(
                  '${semester.semesterNumber}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          semester.name,
                          style: theme.textTheme.titleMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: AppSpacing.xs),
                        status,
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_outlined,
                          size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${AppDateUtils.short(semester.startDate)} — '
                        '${AppDateUtils.short(semester.endDate)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
              onSelected: (value) {
                if (value == 'activate') provider.setActive(semester);
                if (value == 'delete') provider.delete(semester);
              },
              itemBuilder: (context) => [
                if (!semester.isActive)
                  const PopupMenuItem(
                    value: 'activate',
                    child: Text('Set as active'),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}