import '../models/enums.dart';
import '../models/subject.dart';
import 'lecture_service.dart';
import 'resource_service.dart';
import 'syllabus_service.dart';

/// Phase 11 — Subject AI Chat: "Gemini receives lecture OCR + PDFs +
/// PPTs + syllabus." This is the piece that gathers all of that into
/// one grounding block for a single subject, so [ChatService] just has
/// to drop it in front of the conversation.
///
/// Kept separate from [ChatService] itself (which owns the actual
/// Gemini call + message history) the same way `TextExtractionService`
/// is kept separate from the services that use its output — one class
/// per responsibility.
class ChatContextService {
  ChatContextService._();
  static final ChatContextService instance = ChatContextService._();

  /// Soft cap on the total size of the assembled context. Gemini Flash
  /// can take far more than this, but a hard ceiling keeps requests
  /// fast and cheap even for a subject with a semester's worth of
  /// lectures and PDFs — recent lectures and the syllabus are
  /// prioritized over older ones if something has to be dropped.
  static const _maxContextChars = 60000;

  /// Builds the grounding text for [subject]. Returns an empty string
  /// (never null) if the subject has no OCR'd lectures, extracted
  /// resources, or syllabus yet — [ChatService] treats that as "answer
  /// from general knowledge, but say there's nothing subject-specific
  /// yet" rather than as an error.
  Future<String> buildContext(Subject subject) async {
    final sections = <String>[];

    final syllabus = await SyllabusService.instance.getForSubject(subject.id);
    final syllabusText = syllabus?.extractedText?.trim();
    if (syllabusText != null && syllabusText.isNotEmpty) {
      sections.add('=== Syllabus ===\n$syllabusText');
    }

    final resources =
        await ResourceService.instance.watchForSubject(subject.id).first;
    resources.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
    for (final resource in resources) {
      final text = resource.extractedText?.trim();
      if (text == null || text.isEmpty) continue;
      sections.add(
        '=== ${resource.type.label}: ${resource.name} ===\n$text',
      );
    }

    // Lectures are the most day-to-day source, so pull them across all
    // three session types together, newest first — the cap below then
    // naturally favors the most recent classes if there's a lot.
    for (final sessionType in SessionType.values) {
      final lectures = await LectureService.instance
          .watchForSection(subjectId: subject.id, sessionType: sessionType)
          .first;
      for (final lecture in lectures) {
        final text = lecture.ocrText?.trim();
        if (text == null || text.isEmpty) continue;
        sections.add(
          '=== ${sessionType.label} lecture ${lecture.lectureCode} '
          '(${lecture.capturedAt.toIso8601String().split('T').first}) '
          '===\n$text',
        );
      }
    }

    if (sections.isEmpty) return '';
    return _truncate(sections.join('\n\n'), _maxContextChars);
  }

  String _truncate(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return '${text.substring(0, maxChars)}\n\n'
        '[...older content truncated to keep the request a reasonable size...]';
  }
}
