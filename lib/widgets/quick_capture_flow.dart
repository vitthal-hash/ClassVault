import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/models/enums.dart';
import '../core/models/subject.dart';
import '../core/services/lecture_service.dart';
import '../core/services/smart_detection_service.dart';
import '../core/services/subject_service.dart';
import '../screens/lecture_detail_screen.dart';

/// Entry point for Phase 8 — Smart Subject Detection.
///
/// Unlike the Lectures tab's capture flow (Phase 7, subject-scoped),
/// this one starts *before* a subject is chosen: pick the photo first,
/// then figure out where it belongs — either automatically from
/// what's on the timetable right now, or by asking, with the session
/// type (Theory/Lab) still inferred either way. Once saved, Phase 9's
/// `LectureDetailScreen` takes over to run OCR automatically.
class QuickCaptureFlow {
  QuickCaptureFlow._();

  static Future<void> start(BuildContext context, {required int semesterId}) async {
    final source = await _pickSource(context);
    if (source == null || !context.mounted) return;

    final image = await LectureService.instance.pickImage(source);
    if (image == null || !context.mounted) return;

    final detected = await SmartDetectionService.instance.detectNow(
      semesterId: semesterId,
    );
    if (!context.mounted) return;

    if (detected != null) {
      final confirmed = await _confirmDetected(context, detected);
      if (!context.mounted) return;

      if (confirmed == true) {
        await _save(
          context,
          subject: detected.subject,
          sessionType: detected.sessionType,
          image: image,
        );
        return;
      }
      if (confirmed == null) return; // dismissed, not "choose different"
    }

    // Nothing scheduled right now, or the person wants a different
    // subject than what was detected — ask directly.
    final subject = await _pickSubject(context, semesterId: semesterId);
    if (subject == null || !context.mounted) return;

    final sessionType = await SmartDetectionService.instance
        .fallbackSessionType(subject: subject);
    if (!context.mounted) return;

    await _save(
      context,
      subject: subject,
      sessionType: sessionType,
      image: image,
    );
  }

  static Future<ImageSource?> _pickSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
  }

  /// Returns true = save here, false = choose a different subject,
  /// null = dialog dismissed (treated as cancel).
  static Future<bool?> _confirmDetected(
    BuildContext context,
    DetectedSlot detected,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suggested subject'),
        content: Text(
          "It's currently ${detected.subject.name}'s "
          '${detected.sessionType.label} time on your timetable. '
          'Save this photo there?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Choose Different Subject'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Use ${detected.subject.name}'),
          ),
        ],
      ),
    );
  }

  static Future<Subject?> _pickSubject(
    BuildContext context, {
    required int semesterId,
  }) async {
    final subjects = await SubjectService.instance.getForSemester(semesterId);
    if (!context.mounted) return null;

    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No subjects yet — upload a timetable first.'),
        ),
      );
      return null;
    }

    return showModalBottomSheet<Subject>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose Subject',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: subjects.length,
                  itemBuilder: (context, i) {
                    final subject = subjects[i];
                    return ListTile(
                      title: Text(subject.name),
                      subtitle: subject.code == null
                          ? null
                          : Text(subject.code!),
                      onTap: () => Navigator.of(context).pop(subject),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _save(
    BuildContext context, {
    required Subject subject,
    required SessionType sessionType,
    required XFile image,
  }) async {
    try {
      final lecture = await LectureService.instance.saveCapturedImage(
        subject: subject,
        sessionType: sessionType,
        image: image,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved as ${lecture.lectureCode} · ${subject.name} '
              '(${sessionType.label})',
            ),
          ),
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LectureDetailScreen(lecture: lecture),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save photo: $e')),
        );
      }
    }
  }
}
