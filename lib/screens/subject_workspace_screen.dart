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
/// under `subject_tabs/` — this screen only owns the app bar and the
/// tab shell.
///
/// The "add a note" action only floats on the Notes tab. It used to
/// persist across every tab, but almost every other tab already has its
/// own full-width bottom action bar (Add Lecture, Upload Files, Add
/// Slot, the AI Chat input bar, …) — a Scaffold-level FAB floats at a
/// fixed screen position regardless of tab content, so it was sitting
/// directly on top of those buttons on every tab that had one.
class SubjectWorkspaceScreen extends StatefulWidget {
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

  @override
  State<SubjectWorkspaceScreen> createState() => _SubjectWorkspaceScreenState();
}

class _SubjectWorkspaceScreenState extends State<SubjectWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final startIndex = SubjectWorkspaceScreen._sections
        .indexOf(widget.initialSection ?? SubjectSection.theory);
    _tabController = TabController(
      length: SubjectWorkspaceScreen._sections.length,
      initialIndex: startIndex < 0 ? 0 : startIndex,
      vsync: this,
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
    final sections = SubjectWorkspaceScreen._sections;
    final currentSection = sections[_tabController.index];

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<Subject?>(
          // Re-reads the subject so a code edit or pin toggle made
          // from this same screen shows up immediately in the title
          // and menu without navigating away and back.
          stream: SubjectService.instance.watchById(widget.subject.id),
          initialData: widget.subject,
          builder: (context, snapshot) {
            final current = snapshot.data ?? widget.subject;
            return Text(
              current.code == null
                  ? current.name
                  : '${current.name} · ${current.code}',
            );
          },
        ),
        actions: [
          StreamBuilder<Subject?>(
            stream: SubjectService.instance.watchById(widget.subject.id),
            initialData: widget.subject,
            builder: (context, snapshot) {
              final current = snapshot.data ?? widget.subject;
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
          controller: _tabController,
          isScrollable: true,
          tabs: [
            for (final section in sections)
              Tab(icon: Icon(section.icon), text: section.label),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          for (final section in sections) _buildTab(section),
        ],
      ),
      // Only on Notes: every other tab already has its own full-width
      // bottom action (Add Lecture, Upload Files, Add Slot, the AI Chat
      // input bar, …), and a Scaffold FAB floats at a fixed position
      // regardless of which tab is showing, so it used to sit right on
      // top of those buttons.
      floatingActionButton: currentSection == SubjectSection.notes
          ? FloatingActionButton(
              tooltip: 'Add a note',
              onPressed: () =>
                  NoteEditorSheet.showNew(context, subjectId: widget.subject.id),
              child: const Icon(Icons.note_add_outlined),
            )
          : null,
    );
  }

  Widget _buildTab(SubjectSection section) {
    switch (section) {
      case SubjectSection.theory:
        return ScheduleTab(subject: widget.subject, sessionType: SessionType.theory);
      case SubjectSection.lab:
        return ScheduleTab(subject: widget.subject, sessionType: SessionType.lab);
      case SubjectSection.tutorial:
        return ScheduleTab(
          subject: widget.subject,
          sessionType: SessionType.tutorial,
        );
      case SubjectSection.syllabus:
        return SyllabusTab(subject: widget.subject);
      case SubjectSection.resources:
        return ResourcesTab(subject: widget.subject);
      case SubjectSection.lectures:
        return LecturesTab(subject: widget.subject);
      case SubjectSection.assignments:
        return AssignmentsTab(subject: widget.subject);
      case SubjectSection.notes:
        return NotesTab(subject: widget.subject);
      case SubjectSection.aiChat:
        return AiChatTab(subject: widget.subject);
    }
  }
}