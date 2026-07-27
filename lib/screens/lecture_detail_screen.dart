import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../core/models/enums.dart';
import '../core/models/lecture.dart';
import '../core/services/gemini_service.dart';
import '../core/services/lecture_service.dart';
import '../core/services/text_extraction_service.dart';
import '../core/theme/app_tokens.dart';
import '../screens/settings_screen.dart';
import '../utils/date_utils.dart';
import '../widgets/common/section_header.dart';

/// Phase 9 — OCR: "Image -> OCR -> Editable Text. User can edit
/// mistakes. Save. Never OCR again."
///
/// Phase 10 — AI Features: "Each lecture gets Explain, Summarize, Key
/// Points, Important Questions, Generate Notes, Copy, Share. Gemini
/// reads OCR text." Added below the OCR text area in this same screen
/// rather than a separate one, since the AI actions operate on exactly
/// the text this screen already shows and lets you fix.
///
/// Doubles as the lecture "detail" view (photo + full-screen zoom)
/// since reviewing the text side by side with the photo it came from
/// is exactly what makes fixing OCR mistakes practical.
///
/// Phase 15 — Revision: the star icon in the app bar toggles this
/// lecture in/out of the Revision screen's starred list.
class LectureDetailScreen extends StatefulWidget {
  const LectureDetailScreen({super.key, required this.lecture});

  final Lecture lecture;

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  late final TextEditingController _controller;
  bool _runningOcr = false;
  bool _saving = false;
  bool _dirty = false;

  // Phase 10 — AI result state. Only one action's result is kept on
  // screen at a time; re-running clears the previous one rather than
  // stacking a history (that's Phase 11's job, as a real chat).
  AiAction? _activeAction;
  bool _aiLoading = false;
  String? _aiResult;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.lecture.ocrText ?? '');
    _controller.addListener(() {
      if (!_dirty) setState(() => _dirty = true);
    });

    // Already reviewed once before (even if left blank on purpose) —
    // per the plan, never run OCR again on this lecture.
    if (widget.lecture.ocrText == null) {
      _runOcr();
    }
  }

  Future<void> _runOcr() async {
    setState(() => _runningOcr = true);
    try {
      final text = await TextExtractionService.instance
          .extractFromImage(File(widget.lecture.imagePath));
      if (mounted) {
        _controller.text = text;
        _dirty = false; // fresh OCR output isn't an edit yet
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _runningOcr = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await LectureService.instance.updateOcrText(
        widget.lecture,
        _controller.text,
      );
      if (mounted) {
        setState(() => _dirty = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Text saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleStar() async {
    await LectureService.instance.toggleStar(widget.lecture);
    if (mounted) setState(() {});
  }

  void _openFullImage() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(widget.lecture.lectureCode)),
          backgroundColor: Colors.black,
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(widget.lecture.imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  /// Runs [action] against whatever text is currently in the editor —
  /// not necessarily the saved `ocrText` — so a person can fix an OCR
  /// typo and immediately ask for "Explain" without a separate save
  /// step first. (The text still isn't persisted until they tap "Save
  /// Text", same as before Phase 10.)
  Future<void> _runAiAction(AiAction action) async {
    final sourceText = _controller.text.trim();
    if (sourceText.isEmpty) return;

    setState(() {
      _activeAction = action;
      _aiLoading = true;
      _aiResult = null;
      _aiError = null;
    });

    try {
      final result = await GeminiService.instance.runAction(
        action: action,
        sourceText: sourceText,
      );
      if (mounted) setState(() => _aiResult = result);
    } on GeminiApiKeyMissingException {
      if (mounted) {
        setState(() => _aiError =
            'No Gemini API key set yet. Add one in Settings to use AI features.');
      }
    } catch (e) {
      if (mounted) setState(() => _aiError = e.toString());
    } finally {
      if (mounted) setState(() => _aiLoading = false);
    }
  }

  void _copyAiResult() {
    if (_aiResult == null) return;
    Clipboard.setData(ClipboardData(text: _aiResult!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _shareAiResult() {
    if (_aiResult == null) return;
    final label = _activeAction?.label ?? 'Notes';
    SharePlus.instance.share(
      ShareParams(
        text: _aiResult!,
        subject: '${widget.lecture.lectureCode} — $label',
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lecture = widget.lecture;
    final theme = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.lectureCode),
        actions: [
          IconButton(
            tooltip: lecture.isStarred ? 'Remove from Revision' : 'Star for Revision',
            icon: Icon(
              lecture.isStarred ? Icons.star_rounded : Icons.star_border_rounded,
            ),
            onPressed: _toggleStar,
          ),
          if (!_runningOcr)
            IconButton(
              tooltip: 'Re-run OCR',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _runOcr,
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _openFullImage,
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(File(lecture.imagePath), fit: BoxFit.cover),
                          Positioned(
                            right: AppSpacing.xs,
                            bottom: AppSpacing.xs,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: AppRadius.smRadius,
                              ),
                              child: const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.xxs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppDateUtils.short(lecture.capturedAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        if (_runningOcr)
                          const Text(
                            'Reading text…',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  _runningOcr
                      ? const Padding(
                          padding: EdgeInsets.all(AppSpacing.xxl),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Container(
                            height: 220,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerLow,
                              borderRadius: AppRadius.lgRadius,
                            ),
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              expands: true,
                              textAlignVertical: TextAlignVertical.top,
                              onChanged: (_) => setState(() {}), // enable/disable AI chips live
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'No text extracted — tap here to type '
                                    'notes for this lecture instead.',
                              ),
                            ),
                          ),
                        ),
                  if (!_runningOcr) ...[
                    const SectionHeader(
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI Features',
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xs,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: AiAction.values.map((action) {
                          final selected = _activeAction == action;
                          return ChoiceChip(
                            avatar: Icon(action.icon, size: 18),
                            label: Text(action.label),
                            selected: selected,
                            onSelected: (!hasText || _aiLoading)
                                ? null
                                : (_) => _runAiAction(action),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: _buildAiResultArea(theme),
                    ),
                  ],
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        (_runningOcr || _saving || !_dirty) ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save Text'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResultArea(ThemeData theme) {
    if (_aiLoading) {
      return Row(
        children: [
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Asking Gemini for ${_activeAction?.label.toLowerCase()}…'),
        ],
      );
    }

    if (_aiError != null) {
      final keyMissing = _aiError!.startsWith('No Gemini API key');
      return Container(
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
                  Text(_aiError!, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                  if (keyMissing) ...[
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

    if (_aiResult != null) {
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
                  child: Text(
                    _activeAction?.label ?? '',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: _copyAiResult,
                ),
                IconButton(
                  tooltip: 'Share',
                  icon: const Icon(Icons.share_rounded, size: 20),
                  onPressed: _shareAiResult,
                ),
              ],
            ),
            SelectableText(_aiResult!),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}