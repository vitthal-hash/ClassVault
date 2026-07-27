import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/enums.dart';
import '../core/models/subject.dart';
import '../core/services/dashboard_service.dart';
import '../providers/nav_provider.dart';
import '../providers/semester_provider.dart';
import '../utils/constants.dart';
import '../utils/date_utils.dart';
import '../widgets/placeholder_view.dart';
import 'lecture_detail_screen.dart';
import 'revision_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final active = context.watch<SemesterProvider>().active;

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
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => context.read<NavProvider>().setIndex(1),
                child: const Text('Go to Semester'),
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
      appBar: AppBar(
        title: Text('Home · ${active.name}'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _load(active.id),
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async => _load(active.id),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const _SectionHeader(
                  icon: Icons.today_rounded,
                  title: "Today's Classes",
                ),
                if (data.todayClasses.isEmpty)
                  const _EmptySectionCard(text: 'No classes scheduled today.')
                else
                  ...data.todayClasses.map((c) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Text(c.entry.sessionType.codeInitial),
                          ),
                          title: Text(c.subject.name),
                          subtitle: Text(
                            '${c.entry.timeRangeLabel} · '
                            '${c.entry.sessionType.label}'
                            '${c.teacher != null ? ' · ${c.teacher!.name}' : ''}'
                            '${c.entry.room != null ? ' · ${c.entry.room}' : ''}',
                          ),
                          onTap: () => _openSubject(
                            c.subject,
                            section: _sectionFor(c.entry.sessionType),
                          ),
                        ),
                      )),
                const SizedBox(height: 24),

                const _SectionHeader(
                  icon: Icons.upload_file_rounded,
                  title: 'Recent Uploads',
                ),
                if (data.recentUploads.isEmpty)
                  const _EmptySectionCard(text: 'Nothing uploaded yet.')
                else
                  ...data.recentUploads.map((u) => Card(
                        child: ListTile(
                          leading: Icon(
                            u.kind == RecentUploadKind.lecture
                                ? Icons.photo_camera_outlined
                                : Icons.description_outlined,
                          ),
                          title: Text(u.title),
                          subtitle: Text(
                            '${u.subject.name} · ${AppDateUtils.short(u.timestamp)}',
                          ),
                          onTap: () => u.kind == RecentUploadKind.lecture
                              ? Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        LectureDetailScreen(lecture: u.lecture!),
                                  ),
                                )
                              : _openSubject(
                                  u.subject,
                                  section: SubjectSection.resources,
                                ),
                        ),
                      )),
                const SizedBox(height: 24),

                const _SectionHeader(
                  icon: Icons.pending_actions_rounded,
                  title: 'Pending AI',
                ),
                if (data.pendingAi.isEmpty)
                  const _EmptySectionCard(
                    text: 'Every lecture has been reviewed — nothing waiting.',
                  )
                else
                  ...data.pendingAi.map((p) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.hourglass_empty_rounded),
                          title: Text(p.lecture.lectureCode),
                          subtitle: Text(
                            '${p.subject.name} · not reviewed yet — tap to '
                            'run OCR',
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  LectureDetailScreen(lecture: p.lecture),
                            ),
                          ),
                        ),
                      )),
                const SizedBox(height: 24),

                const _SectionHeader(icon: Icons.search_rounded, title: 'Quick Search'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.search_rounded),
                    title: const Text('Search this semester'),
                    subtitle: const Text(
                      'Lectures, resources, and syllabus — by content',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => context.read<NavProvider>().setIndex(4),
                  ),
                ),
                const SizedBox(height: 24),

                const _SectionHeader(icon: Icons.star_rounded, title: 'Revision'),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.star_rounded),
                    title: const Text('Starred lectures'),
                    subtitle: const Text(
                      'Review starred lectures or generate combined notes',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RevisionScreen(semesterId: active.id),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const _SectionHeader(
                  icon: Icons.push_pin_rounded,
                  title: 'Pinned Subjects',
                ),
                if (data.pinnedSubjects.isEmpty)
                  const _EmptySectionCard(
                    text: 'Pin a subject from its workspace to see it here.',
                  )
                else
                  ...data.pinnedSubjects.map((s) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                            child: Text(
                              s.name.isNotEmpty ? s.name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(s.name),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _openSubject(s),
                        ),
                      )),
                if (data.todayClasses.isEmpty && data.recentUploads.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              TimetableUploadScreen(semesterId: active.id),
                        ),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Upload Timetable'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(title, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
