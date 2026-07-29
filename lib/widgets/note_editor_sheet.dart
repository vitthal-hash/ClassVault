import 'package:flutter/material.dart';

import '../core/models/note.dart';
import '../core/services/note_service.dart';
import '../core/services/timetable_service.dart';

/// Add/edit sheet for a quick, free-form [Note]. Used two ways:
/// - `NoteEditorSheet.showNew(context, subjectId: ...)` from the
///   Subject Workspace's persistent "+" action, available on every tab.
/// - `NoteEditorSheet.showEdit(context, note: ...)` from the Notes tab,
///   to revise or delete something already written.
class NoteEditorSheet extends StatefulWidget {
  const NoteEditorSheet({super.key, required this.subjectId, this.note});

  final int subjectId;

  /// Null when creating a new note; the existing note when editing.
  final Note? note;

  static Future<void> showNew(BuildContext context, {required int subjectId}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteEditorSheet(subjectId: subjectId),
    );
  }

  static Future<void> showEdit(BuildContext context, {required Note note}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => NoteEditorSheet(subjectId: note.subjectId, note: note),
    );
  }

  @override
  State<NoteEditorSheet> createState() => _NoteEditorSheetState();
}

class _NoteEditorSheetState extends State<NoteEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  bool _saving = false;
  late bool _remindMe;

  /// Null while checking; true/false once we know whether this subject
  /// has any timetable slots at all. The toggle is meaningless without
  /// one, so it stays disabled with an explanatory hint until then.
  bool? _hasTimetable;

  bool get _isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _bodyController = TextEditingController(text: widget.note?.body ?? '');
    _remindMe = widget.note?.remindMe ?? false;
    _checkTimetable();
  }

  Future<void> _checkTimetable() async {
    final entries = await TimetableService.instance.getForSubject(widget.subjectId);
    if (mounted) setState(() => _hasTimetable = entries.isNotEmpty);
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write something before saving')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      if (_isEditing) {
        await NoteService.instance.update(
          widget.note!,
          title: _titleController.text,
          body: body,
          remindMe: _remindMe,
        );
      } else {
        await NoteService.instance.create(
          subjectId: widget.subjectId,
          title: _titleController.text,
          body: body,
          remindMe: _remindMe,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save note: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await NoteService.instance.delete(widget.note!);
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isEditing ? 'Edit Note' : 'New Note',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (_isEditing)
                IconButton(
                  tooltip: 'Delete note',
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _delete,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title (optional)',
              hintText: 'e.g. Today\'s lecture — Normalization',
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _bodyController,
            minLines: 5,
            maxLines: 12,
            autofocus: !_isEditing,
            decoration: const InputDecoration(
              labelText: 'Note',
              hintText: 'What was taught, what to remember, anything else…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _remindMe,
            onChanged: (_hasTimetable ?? false)
                ? (value) => setState(() => _remindMe = value)
                : null,
            title: const Text('Remind me'),
            subtitle: Text(
              _hasTimetable == null
                  ? 'Checking timetable…'
                  : _hasTimetable!
                      ? "Nudge the evening before this subject's next lecture"
                      : 'Add this subject to your timetable first',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 6),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}