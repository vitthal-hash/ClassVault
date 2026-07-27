import '../models/enums.dart';
import '../models/lecture.dart';
import '../models/resource.dart';
import '../models/subject.dart';
import '../models/teacher.dart';
import '../models/timetable_entry.dart';
import 'lecture_service.dart';
import 'resource_service.dart';
import 'subject_service.dart';
import 'teacher_service.dart';
import 'timetable_service.dart';

/// One row in Home's "Today's Classes" — a timetable slot plus the
/// subject/teacher names already resolved, so the screen doesn't have
/// to look either up itself.
class TodayClass {
  TodayClass({required this.entry, required this.subject, this.teacher});

  final TimetableEntry entry;
  final Subject subject;
  final Teacher? teacher;
}

/// What kind of item a [RecentUpload] wraps — a lecture photo or a
/// Resource Manager file. Assignments (Phase 14) will add a third case
/// once that phase exists.
enum RecentUploadKind { lecture, resource }

/// One row in Home's "Recent Uploads" — a lecture or resource from any
/// subject in the active semester, carrying enough to show and open it.
class RecentUpload {
  RecentUpload({
    required this.kind,
    required this.title,
    required this.subject,
    required this.timestamp,
    this.lecture,
    this.resource,
  });

  final RecentUploadKind kind;
  final String title;
  final Subject subject;
  final DateTime timestamp;
  final Lecture? lecture;
  final Resource? resource;
}

/// One row in Home's "Pending AI" — a lecture that's been captured but
/// never reviewed, so it has no `ocrText` saved yet. Per Phase 9's
/// "never OCR again" rule, a lecture only counts as reviewed once
/// something (even an intentionally blank string) has been saved for
/// it — until then, its AI actions (Phase 10) have no text to run
/// against, so it's "pending".
class PendingAiLecture {
  PendingAiLecture({required this.lecture, required this.subject});

  final Lecture lecture;
  final Subject subject;
}

/// Everything Home needs in one call, matching the plan's dashboard
/// exactly: "Today's Classes, Recent Uploads, Pending AI, Quick
/// Search, Pinned Subjects." (Quick Search has no data of its own —
/// it's just a shortcut into the Search tab, built by the screen.)
class DashboardData {
  DashboardData({
    required this.todayClasses,
    required this.recentUploads,
    required this.pendingAi,
    required this.pinnedSubjects,
  });

  final List<TodayClass> todayClasses;
  final List<RecentUpload> recentUploads;
  final List<PendingAiLecture> pendingAi;
  final List<Subject> pinnedSubjects;

  static final empty = DashboardData(
    todayClasses: [],
    recentUploads: [],
    pendingAi: [],
    pinnedSubjects: [],
  );
}

class DashboardService {
  DashboardService._();
  static final DashboardService instance = DashboardService._();

  static const _recentUploadsLimit = 10;
  static const _pendingAiLimit = 10;

  Future<DashboardData> load(int semesterId) async {
    final subjects = await SubjectService.instance.getForSemester(semesterId);
    if (subjects.isEmpty) return DashboardData.empty;

    final subjectsById = {for (final s in subjects) s.id: s};

    final todayClasses = await _loadTodayClasses(semesterId, subjectsById);
    final recentUploads = await _loadRecentUploads(subjects);
    final pendingAi = await _loadPendingAi(subjects);
    final pinnedSubjects = subjects.where((s) => s.isPinned).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return DashboardData(
      todayClasses: todayClasses,
      recentUploads: recentUploads,
      pendingAi: pendingAi,
      pinnedSubjects: pinnedSubjects,
    );
  }

  Future<List<TodayClass>> _loadTodayClasses(
    int semesterId,
    Map<int, Subject> subjectsById,
  ) async {
    final today = WeekdayX.fromDateTime(DateTime.now());
    final entries = await TimetableService.instance.watchForSemester(semesterId).first;

    final result = <TodayClass>[];
    for (final entry in entries) {
      if (entry.day != today) continue;
      final subject = subjectsById[entry.subjectId];
      if (subject == null) continue;

      Teacher? teacher;
      final teacherId = entry.teacherId;
      if (teacherId != null) {
        teacher = await TeacherService.instance.getById(teacherId);
      }
      result.add(TodayClass(entry: entry, subject: subject, teacher: teacher));
    }
    // watchForSemester already sorts by day then startMinutes.
    return result;
  }

  Future<List<RecentUpload>> _loadRecentUploads(List<Subject> subjects) async {
    final uploads = <RecentUpload>[];

    for (final subject in subjects) {
      for (final sessionType in SessionType.values) {
        final lectures = await LectureService.instance
            .watchForSection(subjectId: subject.id, sessionType: sessionType)
            .first;
        for (final lecture in lectures) {
          uploads.add(RecentUpload(
            kind: RecentUploadKind.lecture,
            title: lecture.lectureCode,
            subject: subject,
            timestamp: lecture.capturedAt,
            lecture: lecture,
          ));
        }
      }

      final resources =
          await ResourceService.instance.watchForSubject(subject.id).first;
      for (final resource in resources) {
        uploads.add(RecentUpload(
          kind: RecentUploadKind.resource,
          title: resource.name,
          subject: subject,
          timestamp: resource.uploadedAt,
          resource: resource,
        ));
      }
    }

    uploads.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return uploads.take(_recentUploadsLimit).toList();
  }

  Future<List<PendingAiLecture>> _loadPendingAi(List<Subject> subjects) async {
    final pending = <PendingAiLecture>[];

    for (final subject in subjects) {
      for (final sessionType in SessionType.values) {
        final lectures = await LectureService.instance
            .watchForSection(subjectId: subject.id, sessionType: sessionType)
            .first;
        for (final lecture in lectures) {
          if (lecture.ocrText == null) {
            pending.add(PendingAiLecture(lecture: lecture, subject: subject));
          }
        }
      }
    }

    pending.sort((a, b) => b.lecture.createdAt.compareTo(a.lecture.createdAt));
    return pending.take(_pendingAiLimit).toList();
  }
}
