import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/services/gemini_service.dart';
import '../core/services/revision_service.dart';
import '../core/theme/app_tokens.dart';
import '../utils/date_utils.dart';
import '../widgets/placeholder_view.dart';
import 'lecture_detail_screen.dart';
import 'settings_screen.dart';

/// Phase 15 — Revision: "Star lecture -> Creates Revision Folder ->
/// Later: Generate Revision Notes." This screen IS the revision folder
/// — every starred lecture across the whole semester, grouped by
/// subject — plus the "later" notes-generation built now rather than
/// deferred, since it's just Phase 10's Gemini call over several
/// lectures' text at once instead of one.
class RevisionScreen extends StatefulWidget {
  const RevisionScreen({super.key, required this.semesterId});

  final int semesterId;

  @override
  State<RevisionScreen> createState() => _RevisionScreenState();
}

class _RevisionScreenState extends State<RevisionScreen> {
  Future<List<StarredLecture>>? _future;
  final Set<int> _selectedLectureIds = {};

  bool _generating = false;
  String? _generatedNotes;
  String? _generationError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _future = RevisionService.instance.load(widget.semesterId);
      _generatedNotes = null;
      _generationError = null;
    });
  }

  void _toggleSelected(int lectureId) {
    setState(() {
      if (_selectedLectureIds.contains(lectureId)) {
        _selectedLectureIds.remove(lectureId);
      } else {
        _selectedLectureIds.add(lectureId);
      }
    });
  }

  Future<void> _generateNotes(List<StarredLecture> all) async {
    final selected =
        all.where((s) => _selectedLectureIds.contains(s.lecture.id)).toList();
    if (selected.isEmpty) return;

    setState(() {
      _generating = true;
      _generatedNotes = null;
      _generationError = null;
    });

    try {
      final notes = await RevisionService.instance.generateRevisionNotes(selected);
      if (mounted) setState(() => _generatedNotes = notes);
    } on GeminiApiKeyMissingException {
      if (mounted) {
        setState(() => _generationError =
            'No Gemini API key set yet. Add one in Settings to generate notes.');
      }
    } catch (e) {
      if (mounted) setState(() => _generationError = e.toString());
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _copyNotes() {
    if (_generatedNotes == null) return;
    Clipboard.setData(ClipboardData(text: _generatedNotes!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _shareNotes() {
    if (_generatedNotes == null) return;
    SharePlus.instance.share(
      ShareParams(text: _generatedNotes!, subject: 'Revision Notes'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revision')),
      body: FutureBuilder<List<StarredLecture>>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final starred = snapshot.data!;

          if (starred.isEmpty) {
            return const PlaceholderView(
              icon: Icons.star_border_rounded,
              title: 'No starred lectures yet',
              subtitle:
                  'Open any lecture and tap the star icon to add it here '
                  'for revision.',
            );
          }

          final bySubject = <String, List<StarredLecture>>{};
          for (final s in starred) {
            bySubject.putIfAbsent(s.subject.name, () => []).add(s);
          }

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => _load(),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      Text(
                        'Select lectures below and generate one combined '
                        'set of revision notes, or tap a lecture to open it.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final entry in bySubject.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: SubjectPalette.colorFor(
                                    entry.value.first.subject.id,
                                  ),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.pill),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                entry.key,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        ...entry.value.map((s) => _StarredLectureTile(
                              starred: s,
                              selected: _selectedLectureIds.contains(s.lecture.id),
                              onToggleSelected: () => _toggleSelected(s.lecture.id),
                              onOpen: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LectureDetailScreen(lecture: s.lecture),
                                ),
                              ),
                            )),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (_generating)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (_generationError != null)
                        _ErrorCard(
                          message: _generationError!,
                          showSettingsLink:
                              _generationError!.startsWith('No Gemini API key'),
                        ),
                      if (_generatedNotes != null)
                        _NotesResultCard(
                          notes: _generatedNotes!,
                          onCopy: _copyNotes,
                          onShare: _shareNotes,
                        ),
                    ],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: (_selectedLectureIds.isEmpty || _generating)
                            ? null
                            : () => _generateNotes(starred),
                        icon: const Icon(Icons.auto_awesome_rounded),
                        label: Text(
                          _selectedLectureIds.isEmpty
                              ? 'Select lectures to generate notes'
                              : 'Generate Notes (${_selectedLectureIds.length} selected)',
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StarredLectureTile extends StatelessWidget {
  const _StarredLectureTile({
    required this.starred,
    required this.selected,
    required this.onToggleSelected,
    required this.onOpen,
  });

  final StarredLecture starred;
  final bool selected;
  final VoidCallback onToggleSelected;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final lecture = starred.lecture;
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? theme.colorScheme.primaryContainer.withOpacity(0.35) : null,
      child: ListTile(
        leading: ClipRRect(
          borderRadius: AppRadius.smRadius,
          child: Image.file(
            File(lecture.imagePath),
            width: 44,
            height: 44,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(lecture.lectureCode),
        subtitle: Text(AppDateUtils.short(lecture.capturedAt)),
        onTap: onOpen,
        trailing: Checkbox(
          value: selected,
          onChanged: (_) => onToggleSelected(),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.showSettingsLink});

  final String message;
  final bool showSettingsLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                if (showSettingsLink) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesResultCard extends StatelessWidget {
  const _NotesResultCard({
    required this.notes,
    required this.onCopy,
    required this.onShare,
  });

  final String notes;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: AppRadius.mdRadius,
        boxShadow: softShadow(context, strength: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Revision Notes', style: theme.textTheme.titleSmall),
              ),
              IconButton(
                tooltip: 'Copy',
                icon: const Icon(Icons.copy_rounded, size: 20),
                onPressed: onCopy,
              ),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share_rounded, size: 20),
                onPressed: onShare,
              ),
            ],
          ),
          SelectableText(notes),
        ],
      ),
    );
  }
}