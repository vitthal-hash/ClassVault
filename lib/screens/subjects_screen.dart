import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/subject.dart';
import '../core/services/subject_service.dart';
import '../core/theme/app_tokens.dart';
import '../providers/nav_provider.dart';
import '../providers/semester_provider.dart';
import '../widgets/placeholder_view.dart';
import '../widgets/quick_capture_flow.dart';
import 'subject_workspace_screen.dart';
import 'timetable_upload_screen.dart';

class SubjectsScreen extends StatelessWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<SemesterProvider>().active;

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Subjects')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: PlaceholderView(
                icon: Icons.menu_book_rounded,
                title: 'No active semester',
                subtitle:
                    'Create a semester first — subjects live inside a '
                    'semester.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => context.read<NavProvider>().setIndex(1),
                  child: const Text('Go to Semester'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<List<Subject>>(
      stream: SubjectService.instance.watchForSemester(active.id),
      builder: (context, snapshot) {
        final subjects = snapshot.data ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text('Subjects · ${active.name}'),
            actions: [
              IconButton(
                tooltip: 'Upload timetable',
                icon: const Icon(Icons.upload_file_rounded),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TimetableUploadScreen(semesterId: active.id),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
            ],
          ),
          // Hidden while the list is empty: that state already has its
          // own full-width "Upload Timetable" button pinned to the
          // bottom, and showing the FAB too meant two overlapping,
          // near-duplicate calls to action in the same corner.
          floatingActionButton: subjects.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: () =>
                      QuickCaptureFlow.start(context, semesterId: active.id),
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Quick Capture'),
                ),
          body: subjects.isEmpty
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Expanded(
                      child: PlaceholderView(
                        icon: Icons.schedule_rounded,
                        title: 'No subjects yet',
                        subtitle:
                            'Upload your timetable (photo or PDF) and '
                            'subjects, teachers, and the weekly schedule '
                            'will be created automatically.',
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => TimetableUploadScreen(
                                semesterId: active.id,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.upload_file_rounded),
                          label: const Text('Upload Timetable'),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.fabClearance,
                  ),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) =>
                      _SubjectCard(subject: subjects[i]),
                ),
        );
      },
    );
  }
}

class _SubjectCard extends StatelessWidget {
  const _SubjectCard({required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SubjectPalette.colorFor(subject.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SubjectWorkspaceScreen(subject: subject),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                foregroundColor: color,
                child: Text(
                  subject.name.isNotEmpty
                      ? subject.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    if (subject.code != null)
                      _CodeChip(code: subject.code!, color: color)
                    else
                      Text(
                        'Theory · Lab · Tutorial · Resources · more',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              if (subject.isPinned)
                Icon(Icons.push_pin_rounded, size: 18, color: color)
              else
                Icon(Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeChip extends StatelessWidget {
  const _CodeChip({required this.code, required this.color});

  final String code;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        code,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}