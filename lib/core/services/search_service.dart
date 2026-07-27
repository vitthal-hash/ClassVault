import '../models/assignment.dart';
import '../models/enums.dart';
import '../models/lecture.dart';
import '../models/note.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/syllabus.dart';
import 'assignment_service.dart';
import 'lecture_service.dart';
import 'note_service.dart';
import 'resource_service.dart';
import 'subject_service.dart';
import 'syllabus_service.dart';

/// What kind of item a [SearchResult] points to — one label per row in
/// the plan's example: "Normalization -> shows Lecture, PDF, PPT,
/// Assignment, Syllabus," plus Notes (added on top of the plan).
enum SearchResultKind { lecture, pdf, ppt, word, image, assignment, note, syllabus }

extension SearchResultKindX on SearchResultKind {
  String get label {
    switch (this) {
      case SearchResultKind.lecture:
        return 'Lecture';
      case SearchResultKind.pdf:
        return 'PDF';
      case SearchResultKind.ppt:
        return 'PPT';
      case SearchResultKind.word:
        return 'Word';
      case SearchResultKind.image:
        return 'Image';
      case SearchResultKind.assignment:
        return 'Assignment';
      case SearchResultKind.note:
        return 'Note';
      case SearchResultKind.syllabus:
        return 'Syllabus';
    }
  }

  static SearchResultKind fromResourceType(ResourceType type) {
    switch (type) {
      case ResourceType.pdf:
        return SearchResultKind.pdf;
      case ResourceType.ppt:
        return SearchResultKind.ppt;
      case ResourceType.word:
        return SearchResultKind.word;
      case ResourceType.image:
        return SearchResultKind.image;
    }
  }
}

/// One hit in the global search — "no filename searching" per the
/// plan, so a match can come from a lecture's OCR text, a resource's
/// extracted text, a syllabus's extracted text, an assignment's title,
/// or a note's body, not just a name. Carries the underlying record so
/// the search screen can open it directly rather than re-querying.
class SearchResult {
  SearchResult({
    required this.kind,
    required this.title,
    required this.subject,
    required this.snippet,
    this.lecture,
    this.resource,
    this.syllabus,
    this.assignment,
    this.note,
  });

  final SearchResultKind kind;
  final String title;
  final Subject subject;

  /// A short excerpt around the matched text, for context in the
  /// results list — falls back to the title when the match was only in
  /// the name/code, not the body text.
  final String snippet;

  final Lecture? lecture;
  final Resource? resource;
  final Syllabus? syllabus;
  final Assignment? assignment;
  final Note? note;
}

/// Phase 12 — Search: "Global search. 'Normalization' -> shows Lecture,
/// PDF, PPT, Assignment, Syllabus. No filename searching." Scoped to
/// one semester at a time (mirrors every other cross-subject view in
/// the app, like the Subjects list), searching every subject inside it.
class SearchService {
  SearchService._();
  static final SearchService instance = SearchService._();

  /// Characters of context kept on each side of a match inside
  /// [SearchResult.snippet].
  static const _snippetRadius = 50;

  Future<List<SearchResult>> search({
    required int semesterId,
    required String query,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final subjects = await SubjectService.instance.getForSemester(semesterId);
    final results = <SearchResult>[];

    for (final subject in subjects) {
      final syllabus = await SyllabusService.instance.getForSubject(subject.id);
      if (syllabus != null) {
        final body = syllabus.extractedText ?? '';
        if (_matches(syllabus.fileName, body, q)) {
          results.add(SearchResult(
            kind: SearchResultKind.syllabus,
            title: syllabus.fileName,
            subject: subject,
            snippet: _snippet(body, q, fallback: syllabus.fileName),
            syllabus: syllabus,
          ));
        }
      }

      final resources =
          await ResourceService.instance.watchForSubject(subject.id).first;
      for (final resource in resources) {
        final body = resource.extractedText ?? '';
        if (_matches(resource.name, body, q)) {
          results.add(SearchResult(
            kind: SearchResultKindX.fromResourceType(resource.type),
            title: resource.name,
            subject: subject,
            snippet: _snippet(body, q, fallback: resource.name),
            resource: resource,
          ));
        }
      }

      for (final sessionType in SessionType.values) {
        final lectures = await LectureService.instance
            .watchForSection(subjectId: subject.id, sessionType: sessionType)
            .first;
        for (final lecture in lectures) {
          final body = lecture.ocrText ?? '';
          if (_matches(lecture.lectureCode, body, q)) {
            results.add(SearchResult(
              kind: SearchResultKind.lecture,
              title: lecture.lectureCode,
              subject: subject,
              snippet: _snippet(body, q, fallback: lecture.lectureCode),
              lecture: lecture,
            ));
          }
        }
      }

      final assignments =
          await AssignmentService.instance.watchForSubject(subject.id).first;
      for (final assignment in assignments) {
        if (_matches(assignment.title, '', q)) {
          results.add(SearchResult(
            kind: SearchResultKind.assignment,
            title: assignment.title,
            subject: subject,
            snippet: assignment.title,
            assignment: assignment,
          ));
        }
      }

      final notes = await NoteService.instance.getForSubject(subject.id);
      for (final note in notes) {
        final title = note.title ?? note.body.split('\n').first;
        if (_matches(title, note.body, q)) {
          results.add(SearchResult(
            kind: SearchResultKind.note,
            title: title,
            subject: subject,
            snippet: _snippet(note.body, q, fallback: title),
            note: note,
          ));
        }
      }
    }

    return results;
  }

  bool _matches(String title, String body, String q) =>
      title.toLowerCase().contains(q) || body.toLowerCase().contains(q);

  String _snippet(String body, String q, {required String fallback}) {
    final lower = body.toLowerCase();
    final idx = lower.indexOf(q);
    if (idx == -1) return fallback; // matched on the name/code, not the body

    final start = (idx - _snippetRadius).clamp(0, body.length);
    final end = (idx + q.length + _snippetRadius).clamp(0, body.length);
    final excerpt = body.substring(start, end).trim();
    return '${start > 0 ? '…' : ''}$excerpt${end < body.length ? '…' : ''}';
  }
}