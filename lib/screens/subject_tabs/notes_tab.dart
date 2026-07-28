import 'package:flutter/material.dart';

import '../../core/models/note.dart';
import '../../core/models/subject.dart';
import '../../core/services/note_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/note_editor_sheet.dart';
import '../../widgets/placeholder_view.dart';

/// Notes tab: every quick note written for this subject, newest first.
/// Adding a new one is via this tab's own floating "+" action — the
/// Subject Workspace only shows that FAB while this tab is active, so
/// it never sits on top of another tab's own bottom action bar (Add
/// Lecture, Upload Files, the AI Chat input bar, …).
class NotesTab extends StatelessWidget {
  const NotesTab({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Note>>(
      stream: NoteService.instance.watchForSubject(subject.id),
      builder: (context, snapshot) {
        final notes = snapshot.data ?? [];

        if (notes.isEmpty) {
          return PlaceholderView(
            icon: Icons.sticky_note_2_outlined,
            title: 'No notes yet',
            subtitle:
                'Tap the + button below to jot down what was taught, a '
                'reminder, or anything else worth keeping.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final note = notes[i];
            final firstLine = note.body.split('\n').first;
            return Card(
              child: ListTile(
                leading: const Icon(Icons.sticky_note_2_outlined),
                title: Text(
                  note.title ?? firstLine,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${AppDateUtils.short(note.updatedAt)}'
                  '${note.title != null ? ' · $firstLine' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => NoteEditorSheet.showEdit(context, note: note),
              ),
            );
          },
        );
      },
    );
  }
}