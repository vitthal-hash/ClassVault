import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/enums.dart';
import '../core/parsing/timetable_parser.dart';
import '../core/theme/app_tokens.dart';
import '../providers/timetable_upload_provider.dart';
import '../widgets/timetable_row_edit_sheet.dart';

class TimetableUploadScreen extends StatelessWidget {
  const TimetableUploadScreen({super.key, required this.semesterId});

  final int semesterId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimetableUploadProvider(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Upload Timetable')),
        body: _UploadBody(semesterId: semesterId),
      ),
    );
  }
}

class _UploadBody extends StatelessWidget {
  const _UploadBody({required this.semesterId});

  final int semesterId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableUploadProvider>();

    switch (provider.stage) {
      case UploadStage.idle:
        return _SourcePicker(error: provider.error);
      case UploadStage.extracting:
        return const _CenteredMessage(
          spinner: true,
          text: 'Reading your timetable…',
        );
      case UploadStage.reviewing:
        return _ReviewList(semesterId: semesterId);
      case UploadStage.saving:
        return const _CenteredMessage(
          spinner: true,
          text: 'Creating subjects and saving your timetable…',
        );
      case UploadStage.done:
        return _DoneView(count: provider.savedCount);
    }
  }
}

class _SourcePicker extends StatelessWidget {
  const _SourcePicker({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<TimetableUploadProvider>();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.upload_file_rounded,
                size: 56, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Upload your timetable',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              "We'll read it and automatically create subjects, teachers, "
              'and the weekly schedule — you just confirm.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: AppRadius.mdRadius,
                ),
                child: Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: provider.pickFromCamera,
              icon: const Icon(Icons.camera_alt_rounded),
              label: const Text('Take a Photo'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: provider.pickFromGallery,
              icon: const Icon(Icons.photo_library_rounded),
              label: const Text('Choose from Gallery'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: provider.pickPdf,
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('Choose a PDF'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text, this.spinner = false});

  final String text;
  final bool spinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spinner) const CircularProgressIndicator(),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _ReviewList extends StatelessWidget {
  const _ReviewList({required this.semesterId});

  final int semesterId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimetableUploadProvider>();
    final rows = provider.rows;
    final completeCount = rows.where((r) => r.isComplete).length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${rows.length} rows found · $completeCount ready to save',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              TextButton.icon(
                onPressed: provider.addBlankRow,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add row'),
              ),
            ],
          ),
        ),
        Expanded(
          child: rows.isEmpty
              ? const Center(child: Text('No rows yet — add one manually.'))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  itemCount: rows.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.xs),
                  itemBuilder: (context, i) {
                    final row = rows[i];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Icon(
                          row.isComplete
                              ? Icons.check_circle_rounded
                              : Icons.error_outline_rounded,
                          color: row.isComplete
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          row.subjectName.isEmpty
                              ? '(no subject name)'
                              : row.subjectName,
                        ),
                        subtitle: Text(_rowSubtitle(row)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          onPressed: () => provider.removeRow(i),
                        ),
                        onTap: () async {
                          final updated =
                              await TimetableRowEditSheet.show(context, row);
                          if (updated != null) provider.updateRow(i, updated);
                        },
                      ),
                    );
                  },
                ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
            ),
          ),
          child: SafeArea(
            minimum: const EdgeInsets.all(AppSpacing.md),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: completeCount == 0
                    ? null
                    : () => provider.confirmAndSave(semesterId),
                child: Text('Save $completeCount row${completeCount == 1 ? '' : 's'}'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _rowSubtitle(ParsedTimetableRow row) {
    final parts = <String>[
      row.day?.label ?? 'No day',
    ];
    if (row.startMinutes != null && row.endMinutes != null) {
      String fmt(int m) =>
          '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
      parts.add('${fmt(row.startMinutes!)}-${fmt(row.endMinutes!)}');
    }
    parts.add(row.sessionType.label);
    if (row.teacherName != null) parts.add(row.teacherName!);
    return parts.join(' · ');
  }
}

class _DoneView extends StatelessWidget {
  const _DoneView({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.check_circle_rounded,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Timetable saved!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '$count timetable ${count == 1 ? 'slot' : 'slots'} created.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go to Subjects'),
            ),
          ],
        ),
      ),
    );
  }
}