import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/subject.dart';
import '../core/services/subject_service.dart';
import '../core/theme/app_tokens.dart';
import '../providers/nav_provider.dart';
import '../providers/semester_provider.dart';
import '../widgets/placeholder_view.dart';
import 'subject_chat_screen.dart';

/// Top-level "AI Chat" nav destination. Per the plan, chat is always
/// scoped to one subject ("chat only with DBMS"), so this screen's
/// only job is picking which subject before handing off to
/// [SubjectChatScreen] — the actual conversation is the same
/// [AiChatTab] the Subject Workspace embeds directly.
class AiChatScreen extends StatelessWidget {
  const AiChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final active = context.watch<SemesterProvider>().active;

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Chat')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: PlaceholderView(
                icon: Icons.smart_toy_outlined,
                title: 'No active semester',
                subtitle:
                    'Create a semester and add subjects first — AI Chat '
                    'is scoped to one subject at a time.',
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

    return Scaffold(
      appBar: AppBar(title: Text('AI Chat · ${active.name}')),
      body: StreamBuilder<List<Subject>>(
        stream: SubjectService.instance.watchForSemester(active.id),
        builder: (context, snapshot) {
          final subjects = snapshot.data ?? [];

          if (subjects.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Expanded(
                  child: PlaceholderView(
                    icon: Icons.smart_toy_outlined,
                    title: 'No subjects yet',
                    subtitle:
                        'Add subjects (via the Subjects tab or a '
                        'timetable upload) — each one gets its own AI '
                        'chat grounded on its lectures, resources, and '
                        'syllabus.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          context.read<NavProvider>().setIndex(2),
                      child: const Text('Go to Subjects'),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.xs,
              AppSpacing.md,
              AppSpacing.xxxl,
            ),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _SubjectChatCard(subject: subjects[i]),
          );
        },
      ),
    );
  }
}

class _SubjectChatCard extends StatelessWidget {
  const _SubjectChatCard({required this.subject});

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
            builder: (_) => SubjectChatScreen(subject: subject),
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
                child: const Icon(Icons.smart_toy_outlined),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Ask about lectures, resources, syllabus',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}