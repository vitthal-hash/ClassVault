import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/subject.dart';
import '../core/services/subject_service.dart';
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
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            QuickCaptureFlow.start(context, semesterId: active.id),
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('Quick Capture'),
      ),
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
                    icon: Icons.schedule_rounded,
                    title: 'No subjects yet',
                    subtitle:
                        'Upload your timetable (photo or PDF) and subjects, '
                        'teachers, and the weekly schedule will be created '
                        'automatically.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
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
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: subjects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final subject = subjects[i];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      subject.name.isNotEmpty
                          ? subject.name[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(subject.name),
                  subtitle: Text(
                    subject.code == null
                        ? 'Theory · Lab · Tutorial · Resources · more'
                        : 'Code: ${subject.code}',
                  ),
                  trailing: subject.isPinned
                      ? const Icon(Icons.push_pin_rounded, size: 20)
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SubjectWorkspaceScreen(subject: subject),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
