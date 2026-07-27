import '../models/lecture.dart';
import '../models/subject.dart';
import 'gemini_service.dart';
import 'lecture_service.dart';
import 'subject_service.dart';

/// One starred lecture plus the subject it belongs to — everything the
/// Revision screen needs to show and open it.
class StarredLecture {
  StarredLecture({required this.lecture, required this.subject});

  final Lecture lecture;
  final Subject subject;
}

/// Phase 15 — Revision: "Star lecture -> Creates Revision Folder ->
/// Later: Generate Revision Notes." There's no separate "folder" table;
/// starring is just a flag on Lecture (see its `isStarred` doc), so
/// this service's job is purely to gather every starred lecture across
/// a semester's subjects, and — going ahead with the "later" part now
/// rather than leaving it for a future phase — turn a chosen set of
/// them into one combined set of revision notes via Gemini.
class RevisionService {
  RevisionService._();
  static final RevisionService instance = RevisionService._();

  Future<List<StarredLecture>> load(int semesterId) async {
    final subjects = await SubjectService.instance.getForSemester(semesterId);
    final result = <StarredLecture>[];

    for (final subject in subjects) {
      final starred = await LectureService.instance.starredForSubject(subject.id);
      for (final lecture in starred) {
        result.add(StarredLecture(lecture: lecture, subject: subject));
      }
    }

    result.sort((a, b) => b.lecture.capturedAt.compareTo(a.lecture.capturedAt));
    return result;
  }

  /// Combines the OCR text of every lecture in [lectures] into one
  /// Gemini prompt and asks for organized revision notes spanning all
  /// of them. Lectures with no reviewed text (`ocrText` null or blank)
  /// are skipped rather than sending Gemini nothing to work with for
  /// that one — same "never OCR again, but can't summarize what was
  /// never reviewed" logic Phase 13's "Pending AI" section already
  /// relies on.
  ///
  /// Throws [GeminiApiKeyMissingException] / [GeminiApiException] same
  /// as every other Gemini call in the app — the caller handles those
  /// exactly like `LectureDetailScreen` already does.
  Future<String> generateRevisionNotes(List<StarredLecture> lectures) async {
    final usable = lectures.where((s) => (s.lecture.ocrText ?? '').trim().isNotEmpty);

    if (usable.isEmpty) {
      throw GeminiApiException(
        "None of the selected lectures have reviewed text yet — open one, "
        "let OCR run, and save it before generating notes from it.",
      );
    }

    final buffer = StringBuffer()
      ..writeln(
        'Combine the following lecture excerpts into one set of clean, '
        'well-organized revision notes. Group related ideas together '
        'even if they come from different lectures, use headings per '
        'topic (not per lecture), and keep it concise enough to review '
        'quickly before an exam.',
      )
      ..writeln();

    for (final s in usable) {
      buffer
        ..writeln('--- ${s.subject.name} · ${s.lecture.lectureCode} ---')
        ..writeln(s.lecture.ocrText!.trim())
        ..writeln();
    }

    return GeminiService.instance.generateRaw(buffer.toString());
  }
}
