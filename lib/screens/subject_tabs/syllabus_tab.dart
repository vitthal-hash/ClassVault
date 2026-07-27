import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models/subject.dart';
import '../../core/models/syllabus.dart';
import '../../core/services/syllabus_service.dart';
import '../../utils/date_utils.dart';
import '../../widgets/placeholder_view.dart';

/// Syllabus tab (Phase 5): upload a PDF once, text is extracted
/// automatically and stored so later phases (Search, Subject AI Chat)
/// never need to re-parse the file.
class SyllabusTab extends StatefulWidget {
  const SyllabusTab({super.key, required this.subject});

  final Subject subject;

  @override
  State<SyllabusTab> createState() => _SyllabusTabState();
}

class _SyllabusTabState extends State<SyllabusTab> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = result?.files.single.path;
      if (path == null) return; // user cancelled

      setState(() => _uploading = true);
      await SyllabusService.instance.upload(
        subject: widget.subject,
        pickedFile: File(path),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload syllabus: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(Syllabus syllabus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove syllabus?'),
        content: const Text(
          'This deletes the stored PDF and its extracted text. You can '
          'always upload it again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await SyllabusService.instance.delete(syllabus);
    }
  }

  void _showExtractedText(String text) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Extracted Text',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    text.trim().isEmpty
                        ? 'No text could be extracted from this PDF — it '
                            'may be a scanned image without a text layer.'
                        : text,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Syllabus?>(
      stream: SyllabusService.instance.watchForSubject(widget.subject.id),
      builder: (context, snapshot) {
        final syllabus = snapshot.data;

        if (syllabus == null) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Expanded(
                child: PlaceholderView(
                  icon: Icons.description_outlined,
                  title: 'No syllabus yet',
                  subtitle:
                      'Upload the syllabus PDF once — its text is '
                      'extracted automatically so Search and Subject AI '
                      'Chat can use it later.',
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    _uploading ? 'Extracting…' : 'Upload Syllabus (PDF)',
                  ),
                ),
              ),
            ],
          );
        }

        final charCount = syllabus.extractedText?.trim().length ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.picture_as_pdf_outlined),
                ),
                title: Text(syllabus.fileName),
                subtitle: Text(
                  charCount == 0
                      ? 'Uploaded ${AppDateUtils.short(syllabus.uploadedAt)} '
                          '· no text detected'
                      : 'Uploaded ${AppDateUtils.short(syllabus.uploadedAt)} '
                          '· $charCount characters extracted',
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () =>
                  _showExtractedText(syllabus.extractedText ?? ''),
              icon: const Icon(Icons.article_outlined),
              label: const Text('View extracted text'),
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _uploading ? null : _pickAndUpload,
              icon: _uploading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded),
              label: Text(_uploading ? 'Extracting…' : 'Replace Syllabus'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _confirmDelete(syllabus),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              label: Text(
                'Remove',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}