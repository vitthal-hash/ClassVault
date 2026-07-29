import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/models/subject.dart';
import '../core/services/assignment_service.dart';
import 'date_field.dart';

class CreateAssignmentSheet extends StatefulWidget {
  const CreateAssignmentSheet({super.key, required this.subject});

  final Subject subject;

  static Future<void> show(BuildContext context, Subject subject) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CreateAssignmentSheet(subject: subject),
    );
  }

  @override
  State<CreateAssignmentSheet> createState() => _CreateAssignmentSheetState();
}

class _CreateAssignmentSheetState extends State<CreateAssignmentSheet> {
  final _titleController = TextEditingController();
  DateTime? _deadline;
  File? _pickedFile;
  String? _pickedFileName;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      _pickedFile = File(path);
      _pickedFileName = path.split('/').last;
      // Default the title to the file name (minus its extension) if the
      // person hasn't typed one — works for any extension, not just PDF.
      if (_titleController.text.trim().isEmpty) {
        final dot = _pickedFileName!.lastIndexOf('.');
        _titleController.text =
            dot > 0 ? _pickedFileName!.substring(0, dot) : _pickedFileName!;
      }
    });
  }

  IconData get _pickedFileIcon {
    if (_pickedFileName == null) return Icons.attach_file_rounded;
    final ext = _pickedFileName!.split('.').last.toLowerCase();
    if (ext == 'doc' || ext == 'docx') return Icons.description_rounded;
    return Icons.picture_as_pdf_rounded;
  }

  Future<void> _submit() async {
    if (_deadline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick a deadline')),
      );
      return;
    }
    if (_pickedFile == null && _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Give it a title, or attach a file to name it after"),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await AssignmentService.instance.upload(
        subject: widget.subject,
        title: _titleController.text,
        deadline: _deadline!,
        file: _pickedFile,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save assignment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          Text(
            'New Assignment',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: Icon(_pickedFileIcon),
                  label: Text(
                    _pickedFileName ?? 'Attach a file (optional)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              if (_pickedFile != null)
                IconButton(
                  tooltip: 'Remove attachment',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _pickedFile = null;
                    _pickedFileName = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              helperText:
                  'Required if you skip the attachment — otherwise the '
                  'file name is used.',
            ),
          ),
          const SizedBox(height: 14),
          DateField(
            label: 'Deadline',
            value: _deadline,
            onChanged: (d) => setState(() => _deadline = d),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save Assignment'),
          ),
        ],
      ),
    );
  }
}