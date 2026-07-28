import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/resource.dart';
import '../../core/models/subject.dart';
import '../../core/services/resource_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/file_opener.dart';
import '../../widgets/placeholder_view.dart';

/// Resource Manager tab (Phase 6): upload any mix of PDF/PPT/Word/Image
/// files into this subject. PDF and Image get their text extracted
/// automatically on upload; PPT/Word are stored as-is until a text
/// extractor for them is built in a later phase (per the plan's own
/// "PPT Text Extractor (later)" note).
class ResourcesTab extends StatefulWidget {
  const ResourcesTab({super.key, required this.subject});

  final Subject subject;

  @override
  State<ResourcesTab> createState() => _ResourcesTabState();
}

class _ResourcesTabState extends State<ResourcesTab> {
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf', 'ppt', 'pptx', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp',
        ],
        allowMultiple: true,
      );
      final paths = result?.files
          .map((f) => f.path)
          .whereType<String>()
          .toList();
      if (paths == null || paths.isEmpty) return; // user cancelled

      setState(() => _uploading = true);
      final outcome = await ResourceService.instance.uploadAll(
        subject: widget.subject,
        pickedFiles: paths.map(File.new).toList(),
      );

      if (mounted && outcome.skipped.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Skipped ${outcome.skipped.length} unsupported file"
              "${outcome.skipped.length == 1 ? '' : 's'}: "
              '${outcome.skipped.join(', ')}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _confirmDelete(Resource resource) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove file?'),
        content: Text('This deletes "${resource.name}" from local storage.'),
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
      await ResourceService.instance.delete(resource);
    }
  }

  Future<void> _openResource(Resource resource) =>
      openStoredFile(context, path: resource.filePath, title: resource.name);

  void _showExtractedText(Resource resource) {
    final text = resource.extractedText ?? '';
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
                'Extracted text · ${resource.name}',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Used for search and AI features — the original file is '
                'unchanged.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: SelectableText(
                    text.trim().isEmpty
                        ? 'No text could be extracted from this file.'
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

  IconData _iconFor(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return Icons.picture_as_pdf_outlined;
      case ResourceType.ppt:
        return Icons.slideshow_outlined;
      case ResourceType.word:
        return Icons.description_outlined;
      case ResourceType.image:
        return Icons.image_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Resource>>(
      stream: ResourceService.instance.watchForSubject(widget.subject.id),
      builder: (context, snapshot) {
        final resources = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: resources.isEmpty
                  ? const PlaceholderView(
                      icon: Icons.folder_outlined,
                      title: 'No resources yet',
                      subtitle:
                          'Upload PDFs, PPTs, Word docs, or images for '
                          'this subject. PDFs and images get their text '
                          'extracted automatically.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: resources.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) {
                        final resource = resources[i];
                        final hasText =
                            (resource.extractedText?.trim().isNotEmpty ??
                                false);
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(_iconFor(resource.type)),
                            ),
                            title: Text(resource.name),
                            subtitle: Text(
                              '${resource.type.label} · '
                              '${AppDateUtils.short(resource.uploadedAt)}'
                              '${hasText ? ' · text extracted' : ''}',
                            ),
                            onTap: () => _openResource(resource),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                switch (value) {
                                  case 'open':
                                    _openResource(resource);
                                  case 'text':
                                    _showExtractedText(resource);
                                  case 'remove':
                                    _confirmDelete(resource);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'open',
                                  child: ListTile(
                                    leading: Icon(Icons.open_in_new_rounded),
                                    title: Text('Open'),
                                  ),
                                ),
                                if (hasText)
                                  const PopupMenuItem(
                                    value: 'text',
                                    child: ListTile(
                                      leading: Icon(Icons.article_outlined),
                                      title: Text('View extracted text'),
                                    ),
                                  ),
                                const PopupMenuItem(
                                  value: 'remove',
                                  child: ListTile(
                                    leading: Icon(Icons.delete_outline_rounded),
                                    title: Text('Remove'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _uploading ? null : _pickAndUpload,
                  icon: _uploading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(_uploading ? 'Uploading…' : 'Upload Files'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}