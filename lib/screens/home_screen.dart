import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/enums.dart';
import '../core/models/subject.dart';
import '../core/services/dashboard_service.dart';
import '../core/theme/app_tokens.dart';
import '../providers/nav_provider.dart';
import '../providers/semester_provider.dart';
import '../utils/date_utils.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/common/section_header.dart';
import '../widgets/placeholder_view.dart';
import 'lecture_detail_screen.dart';
import 'revision_screen.dart';
import 'semester_screen.dart';
import 'subject_workspace_screen.dart';
import 'timetable_upload_screen.dart';

/// Home (Phase 13): "Today's Classes, Recent Uploads, Pending AI, Quick
/// Search, Pinned Subjects." Every section here reads through services
/// earlier phases already built — [DashboardService] just assembles
/// them into one snapshot. Loaded imperatively (not a live
/// StreamBuilder) since it spans several collections at once;
/// pull-to-refresh and a manual refresh action both re-run it.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<DashboardData>? _future;
  int? _loadedSemesterId;

  void _load(int semesterId) {
    _loadedSemesterId = semesterId;
    setState(() {
      _future = DashboardService.instance.load(semesterId);
    });
  }

  void _openSubject(Subject subject, {SubjectSection? section}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            SubjectWorkspaceScreen(subject: subject, initialSection: section),
      ),
    );
  }

  SubjectSection _sectionFor(SessionType sessionType) {
    switch (sessionType) {
      case SessionType.theory:
        return SubjectSection.theory;
      case SessionType.lab:
        return SubjectSection.lab;
      case SessionType.tutorial:
        return SubjectSection.tutorial;
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final active = context.watch<SemesterProvider>().active;
    final theme = Theme.of(context);

    if (active == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Home')),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Expanded(
              child: PlaceholderView(
                icon: Icons.home_rounded,
                title: 'No active semester',
                subtitle:
                    'Create a semester to see today\'s classes, recent '
                    'uploads, and everything else here.',
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const SemesterScreen()),
                  ),
                  child: const Text('Go to Semester'),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_loadedSemesterId != active.id) {
      _load(active.id);
    }

    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<DashboardData>(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final data = snapshot.data!;

            return RefreshIndicator(
              onRefresh: () async => _load(active.id),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.xs,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  _HomeHeader(
                    greeting: _greeting,
                    semesterName: active.name,
                    onRefresh: () => _load(active.id),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  const SectionHeader(
                    icon: Icons.today_rounded,
                    title: "Today's Classes",
                  ),
                  if (data.todayClasses.isEmpty)
                    const InlineEmptyState(
                      icon: Icons.free_breakfast_outlined,
                      text: 'No classes scheduled today. Enjoy the break!',
                    )
                  else
                    ...data.todayClasses.map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _TodayClassCard(
                          todayClass: c,
                          onTap: () => _openSubject(
                            c.subject,
                            section: _sectionFor(c.entry.sessionType),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  const SectionHeader(
                    icon: Icons.upload_file_rounded,
                    title: 'Recent Uploads',
                  ),
                  if (data.recentUploads.isEmpty)
                    const InlineEmptyState(
                      icon: Icons.cloud_off_outlined,
                      text: 'Nothing uploaded yet.',
                    )
                  else
                    ..._withDividers(
                      data.recentUploads.map(
                        (u) => _UploadTile(
                          upload: u,
                          onTap: () => u.kind == RecentUploadKind.lecture
                              ? Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => LectureDetailScreen(
                                      lecture: u.lecture!,
                                    ),
                                  ),
                                )
                              : _openSubject(
                                  u.subject,
                                  section: SubjectSection.resources,
                                ),
                        ),
                      ),
                      theme,
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  const SectionHeader(
                    icon: Icons.pending_actions_rounded,
                    title: 'Pending AI',
                  ),
                  if (data.pendingAi.isEmpty)
                    const InlineEmptyState(
                      icon: Icons.check_circle_outline_rounded,
                      text:
                          'Every lecture has been reviewed — nothing waiting.',
                    )
                  else
                    ..._withDividers(
                      data.pendingAi.map(
                        (p) => _PendingAiTile(
                          pending: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LectureDetailScreen(lecture: p.lecture),
                            ),
                          ),
                        ),
                      ),
                      theme,
                    ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    children: [
                      Expanded(
                        child: _QuickAccessCard(
                          icon: Icons.search_rounded,
                          label: 'Search',
                          subtitle: 'By content',
                          onTap: () =>
                              context.read<NavProvider>().setIndex(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _QuickAccessCard(
                          icon: Icons.star_rounded,
                          label: 'Revision',
                          subtitle: 'Starred lectures',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  RevisionScreen(semesterId: active.id),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  const SectionHeader(
                    icon: Icons.push_pin_rounded,
                    title: 'Pinned Subjects',
                  ),
                  if (data.pinnedSubjects.isEmpty)
                    const InlineEmptyState(
                      icon: Icons.push_pin_outlined,
                      text: 'Pin a subject from its workspace to see it here.',
                    )
                  else
                    ..._withDividers(
                      data.pinnedSubjects.map(
                        (s) => _PinnedSubjectTile(
                          subject: s,
                          onTap: () => _openSubject(s),
                        ),
                      ),
                      theme,
                    ),

                  if (data.todayClasses.isEmpty &&
                      data.recentUploads.isEmpty) ...[
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
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
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Wraps a list of section rows into a single soft-bordered card with
  /// thin dividers between rows, so a section reads as one cohesive
  /// surface instead of a stack of separate cards.
  List<Widget> _withDividers(Iterable<Widget> rows, ThemeData theme) {
    final list = rows.toList();
    return [
      Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: AppRadius.lgRadius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) Divider(height: 1, color: theme.colorScheme.outlineVariant),
              list[i],
            ],
          ],
        ),
      ),
    ];
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greeting,
    required this.semesterName,
    required this.onRefresh,
  });

  final String greeting;
  final String semesterName;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(semesterName, style: theme.textTheme.headlineSmall),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: AppRadius.mdRadius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ),
      ],
    );
  }
}

class _TodayClassCard extends StatelessWidget {
  const _TodayClassCard({required this.todayClass, required this.onTap});

  final TodayClass todayClass;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subject = todayClass.subject;
    final entry = todayClass.entry;
    final color = SubjectPalette.colorFor(subject.id);

    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
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
                  entry.sessionType.codeInitial,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(subject.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.timeRangeLabel} · ${entry.sessionType.label}'
                      '${todayClass.teacher != null ? ' · ${todayClass.teacher!.name}' : ''}'
                      '${entry.room != null ? ' · ${entry.room}' : ''}',
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

class _UploadTile extends StatelessWidget {
  const _UploadTile({required this.upload, required this.onTap});

  final RecentUpload upload;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLecture = upload.kind == RecentUploadKind.lecture;
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: AppRadius.smRadius,
        ),
        child: Icon(
          isLecture ? Icons.photo_camera_outlined : Icons.description_outlined,
          size: 20,
          color: theme.colorScheme.primary,
        ),
      ),
      title: Text(upload.title, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${upload.subject.name} · ${AppDateUtils.short(upload.timestamp)}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 20),
    );
  }
}

class _PendingAiTile extends StatelessWidget {
  const _PendingAiTile({required this.pending, required this.onTap});

  final PendingAiLecture pending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: theme.colorScheme.tertiaryContainer,
          borderRadius: AppRadius.smRadius,
        ),
        child: Icon(Icons.hourglass_empty_rounded,
            size: 20, color: theme.colorScheme.tertiary),
      ),
      title: Text(pending.lecture.lectureCode, style: theme.textTheme.titleSmall),
      subtitle: Text(
        '${pending.subject.name} · not reviewed yet — tap to run OCR',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 20),
    );
  }
}

class _PinnedSubjectTile extends StatelessWidget {
  const _PinnedSubjectTile({required this.subject, required this.onTap});

  final Subject subject;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = SubjectPalette.colorFor(subject.id);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.15),
        foregroundColor: color,
        child: Text(
          subject.name.isNotEmpty ? subject.name[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      title: Text(subject.name, style: theme.textTheme.titleSmall),
      trailing: Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant, size: 20),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHigh,
      borderRadius: AppRadius.lgRadius,
      child: InkWell(
        borderRadius: AppRadius.lgRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgRadius,
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: AppRadius.smRadius,
                ),
                child: Icon(icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(label, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}