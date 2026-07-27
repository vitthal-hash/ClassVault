import 'package:flutter/material.dart';

import '../core/models/enums.dart';
import '../core/models/subject.dart';
import '../core/services/subject_service.dart';
import '../utils/constants.dart';
import '../widgets/edit_subject_code_sheet.dart';
import '../widgets/note_editor_sheet.dart';
import 'subject_tabs/ai_chat_tab.dart';
import 'subject_tabs/assignments_tab.dart';
import 'subject_tabs/lectures_tab.dart';
import 'subject_tabs/notes_tab.dart';
import 'subject_tabs/resources_tab.dart';
import 'subject_tabs/schedule_tab.dart';
import 'subject_tabs/syllabus_tab.dart';

/// Every subject becomes its own workspace with nine tabs, matching the
/// project plan plus Notes (added on top of the plan, for the person's
/// own free-form notes). Each tab's real content lives in its own file
/// under `subject_tabs/` — this screen only owns the app bar, the tab
/// shell, and the persistent "add a note" action that follows you
/// across every tab.
class SubjectWorkspaceScreen extends StatelessWidget {
  const SubjectWorkspaceScreen({
    super.key,
    required this.subject,
    this.initialSection,
  });

  final Subject subject;

  /// Which tab to open on, e.g. jumping straight to Resources from a
  /// Search result (Phase 12). Defaults to Theory when omitted, same as
  /// tapping the subject from the Subjects list always did.
  final SubjectSection? initialSection;

  static const _sections = [
    SubjectSection.theory,
    SubjectSection.lab,
    SubjectSection.tutorial,
    SubjectSection.resources,
    SubjectSection.lectures,
    SubjectSection.assignments,
    SubjectSection.syllabus,
    SubjectSection.notes,
    SubjectSection.aiChat,
  ];

  Future<void> _confirmDeleteSubject(BuildContext context, Subject current) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subject?'),
        content: Text(
          'This permanently deletes "${current.name}" — its timetable '
          'slots, lectures, resources, syllabus, assignments, notes, '
          'and AI chat history all go with it. This can\'t be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await SubjectService.instance.delete(current);
    if (!context.mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('"${current.name}" deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startIndex = _sections.indexOf(initialSection ?? SubjectSection.theory);

    return DefaultTabController(
      length: _sections.length,
      initialIndex: startIndex < 0 ? 0 : startIndex,
      child: Scaffold(
        appBar: AppBar(
          title: StreamBuilder<Subject?>(
            // Re-reads the subject so a code edit or pin toggle made
            // from this same screen shows up immediately in the title
            // and menu without navigating away and back.
            stream: SubjectService.instance.watchById(subject.id),
            initialData: subject,
            builder: (context, snapshot) {
              final current = snapshot.data ?? subject;
              return Text(
                current.code == null
                    ? current.name
                    : '${current.name} · ${current.code}',
              );
            },
          ),
          actions: [
            StreamBuilder<Subject?>(
              stream: SubjectService.instance.watchById(subject.id),
              initialData: subject,
              builder: (context, snapshot) {
                final current = snapshot.data ?? subject;
                return PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'pin':
                        SubjectService.instance.togglePin(current);
                        break;
                      case 'code':
                        EditSubjectCodeSheet.show(context, current);
                        break;
                      case 'delete':
                        _confirmDeleteSubject(context, current);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: ListTile(
                        leading: Icon(
                          current.isPinned
                              ? Icons.push_pin_rounded
                              : Icons.push_pin_outlined,
                        ),
                        title: Text(
                          current.isPinned ? 'Unpin from Home' : 'Pin to Home',
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'code',
                      child: ListTile(
                        leading: Icon(Icons.sell_outlined),
                        title: Text('Edit subject code'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          'Delete subject',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (final section in _sections)
                Tab(icon: Icon(section.icon), text: section.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final section in _sections) _buildTab(section),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Add a note',
          onPressed: () => NoteEditorSheet.showNew(context, subjectId: subject.id),
          child: const Icon(Icons.note_add_outlined),
        ),
      ),
    );
  }

  Widget _buildTab(SubjectSection section) {
    switch (section) {
      case SubjectSection.theory:
        return ScheduleTab(subject: subject, sessionType: SessionType.theory);
      case SubjectSection.lab:
        return ScheduleTab(subject: subject, sessionType: SessionType.lab);
      case SubjectSection.tutorial:
        return ScheduleTab(
          subject: subject,
          sessionType: SessionType.tutorial,
        );
      case SubjectSection.syllabus:
        return SyllabusTab(subject: subject);
      case SubjectSection.resources:
        return ResourcesTab(subject: subject);
      case SubjectSection.lectures:
        return LecturesTab(subject: subject);
      case SubjectSection.assignments:
        return AssignmentsTab(subject: subject);
      case SubjectSection.notes:
        return NotesTab(subject: subject);
      case SubjectSection.aiChat:
        return AiChatTab(subject: subject);
    }
  }
}