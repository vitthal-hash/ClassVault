import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/models/enums.dart';
import '../../core/models/lecture.dart';
import '../../core/models/subject.dart';
import '../../core/services/lecture_service.dart';
import '../../utils/constants.dart';
import '../../utils/date_utils.dart';
import '../../widgets/placeholder_view.dart';
import '../lecture_detail_screen.dart';

/// Lecture Upload tab (Phase 7): "DBMS -> Theory -> + -> Camera or
/// Gallery" from the plan. One tab covers Theory/Lab/Tutorial via a
/// segmented switcher at the top, since a lecture photo always belongs
/// to exactly one of those three sections.
///
/// Phase 8 (Smart Subject Detection) added a separate Quick Capture
/// entry point (from the Subjects screen) for when no subject has been
/// picked yet; this tab's own switcher stays manual since you're
/// already inside a subject here. Phase 9 (OCR) runs text recognition
/// automatically right after a photo is saved — see
/// `LectureDetailScreen`, which this tab opens immediately afterward.
class LecturesTab extends StatefulWidget {
  const LecturesTab({super.key, required this.subject});

  final Subject subject;

  @override
  State<LecturesTab> createState() => _LecturesTabState();
}

class _LecturesTabState extends State<LecturesTab> {
  SessionType _sessionType = SessionType.theory;
  bool _capturing = false;

  Future<void> _showSourceSheet() async {
    final source = await showModalBottomSheet<_LectureSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(_LectureSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(_LectureSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    setState(() => _capturing = true);
    try {
      final lecture = source == _LectureSource.camera
          ? await LectureService.instance.captureFromCamera(
              subject: widget.subject,
              sessionType: _sessionType,
            )
          : await LectureService.instance.pickFromGallery(
              subject: widget.subject,
              sessionType: _sessionType,
            );

      if (mounted && lecture != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LectureDetailScreen(lecture: lecture),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _confirmDelete(Lecture lecture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete lecture?'),
        content: Text('This deletes "${lecture.lectureCode}" from local storage.'),
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
      await LectureService.instance.delete(lecture);
    }
  }

  void _openDetail(Lecture lecture) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LectureDetailScreen(lecture: lecture),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: SegmentedButton<SessionType>(
            segments: const [
              ButtonSegment(
                value: SessionType.theory,
                label: Text('Theory'),
              ),
              ButtonSegment(value: SessionType.lab, label: Text('Lab')),
              ButtonSegment(
                value: SessionType.tutorial,
                label: Text('Tutorial'),
              ),
            ],
            selected: {_sessionType},
            onSelectionChanged: (selection) {
              setState(() => _sessionType = selection.first);
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Lecture>>(
            stream: LectureService.instance.watchForSection(
              subjectId: widget.subject.id,
              sessionType: _sessionType,
            ),
            builder: (context, snapshot) {
              final lectures = snapshot.data ?? [];
              if (lectures.isEmpty) {
                return PlaceholderView(
                  icon: Icons.photo_camera_outlined,
                  title: 'No ${_sessionType.label.toLowerCase()} lectures yet',
                  subtitle: 'Tap "Add Lecture" below to capture or pick a '
                      'photo. It gets a code like '
                      '${_exampleCode(widget.subject)} automatically.',
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                ),
                itemCount: lectures.length,
                itemBuilder: (context, i) {
                  final lecture = lectures[i];
                  return _LectureTile(
                    lecture: lecture,
                    onTap: () => _openDetail(lecture),
                    onDelete: () => _confirmDelete(lecture),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _capturing ? null : _showSourceSheet,
              icon: _capturing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined),
              label: Text(_capturing ? 'Saving…' : 'Add Lecture'),
            ),
          ),
        ),
      ],
    );
  }

  String _exampleCode(Subject subject) {
    final prefix = (subject.code?.trim().isNotEmpty ?? false)
        ? subject.code!.toUpperCase()
        : 'SUBJ';
    return '${prefix}_${_sessionType.codeInitial}_001';
  }
}

enum _LectureSource { camera, gallery }

class _LectureTile extends StatelessWidget {
  const _LectureTile({
    required this.lecture,
    required this.onTap,
    required this.onDelete,
  });

  final Lecture lecture;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(lecture.imagePath),
                    fit: BoxFit.cover,
                  ),
                  if (lecture.isStarred)
                    const Positioned(
                      top: 6,
                      left: 6,
                      child: Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 22,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spaceS,
                vertical: AppConstants.spaceXS,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          lecture.lectureCode,
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          AppDateUtils.short(lecture.capturedAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    iconSize: 18,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}