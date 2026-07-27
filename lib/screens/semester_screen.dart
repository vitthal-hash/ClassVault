import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/semester.dart';
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
      appBar: AppBar(title: const Text('Semester')),
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
              padding: const EdgeInsets.all(16),
              itemCount: semesters.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        semester.name,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      if (semester.isActive) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Active',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${AppDateUtils.short(semester.startDate)} — '
                    '${AppDateUtils.short(semester.endDate)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
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
