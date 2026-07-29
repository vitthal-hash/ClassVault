import 'package:flutter/material.dart';

/// Day of week for a timetable slot.
enum Weekday { monday, tuesday, wednesday, thursday, friday, saturday, sunday }

extension WeekdayX on Weekday {
  String get label {
    switch (this) {
      case Weekday.monday:
        return 'Monday';
      case Weekday.tuesday:
        return 'Tuesday';
      case Weekday.wednesday:
        return 'Wednesday';
      case Weekday.thursday:
        return 'Thursday';
      case Weekday.friday:
        return 'Friday';
      case Weekday.saturday:
        return 'Saturday';
      case Weekday.sunday:
        return 'Sunday';
    }
  }

  static Weekday? fromText(String raw) {
    final t = raw.trim().toLowerCase();
    for (final day in Weekday.values) {
      if (day.label.toLowerCase() == t || day.label.toLowerCase().startsWith(t) && t.length >= 3) {
        return day;
      }
    }
    return null;
  }

  /// [DateTime.weekday] is 1 (Monday) .. 7 (Sunday); this enum is
  /// declared in the same Monday-first order, so it's a direct index
  /// map. Used by Phase 8 (Smart Subject Detection) to ask "what's
  /// scheduled right now?".
  static Weekday fromDateTime(DateTime dt) => Weekday.values[dt.weekday - 1];
}

/// Theory / Lab / Tutorial — used by TimetableEntry and later by the
/// Subject workspace (Phase 4) and Lecture upload (Phase 7).
enum SessionType { theory, lab, tutorial }



extension SessionTypeX on SessionType {
  String get label {
    switch (this) {
      case SessionType.theory:
        return 'Theory';
      case SessionType.lab:
        return 'Lab';
      case SessionType.tutorial:
        return 'Tutorial';
    }
  }

  static SessionType fromText(String raw) {
    final t = raw.trim().toLowerCase();
    if (t.startsWith('lab') || t.startsWith('pract')) return SessionType.lab;
    if (t.startsWith('tut')) return SessionType.tutorial;
    return SessionType.theory;
  }

  /// Short initial used in generated lecture IDs, e.g. `DBMS_T_005` for
  /// Theory. Tutorial uses "TU" so it can't be confused with Theory's "T".
  String get codeInitial {
    switch (this) {
      case SessionType.theory:
        return 'T';
      case SessionType.lab:
        return 'L';
      case SessionType.tutorial:
        return 'TU';
    }
  }
}

enum SubjectSection {
  theory,
  lab,
  tutorial,
  resources,
  lectures,
  assignments,
  syllabus,
  notes,
  aiChat,
}

extension SubjectSectionX on SubjectSection {
  String get label {
    switch (this) {
      case SubjectSection.theory:
        return 'Theory';
      case SubjectSection.lab:
        return 'Lab';
      case SubjectSection.tutorial:
        return 'Tutorial';
      case SubjectSection.resources:
        return 'Resources';
      case SubjectSection.lectures:
        return 'Lectures';
      case SubjectSection.assignments:
        return 'Assignments';
      case SubjectSection.syllabus:
        return 'Syllabus';
      case SubjectSection.notes:
        return 'Notes';
      case SubjectSection.aiChat:
        return 'AI Chat';
    }
  }

  IconData get icon {
    switch (this) {
      case SubjectSection.theory:
        return Icons.menu_book_rounded;
      case SubjectSection.lab:
        return Icons.science_rounded;
      case SubjectSection.tutorial:
        return Icons.school_rounded;
      case SubjectSection.resources:
        return Icons.folder_rounded;
      case SubjectSection.lectures:
        return Icons.photo_library_rounded;
      case SubjectSection.assignments:
        return Icons.assignment_rounded;
      case SubjectSection.syllabus:
        return Icons.description_rounded;
      case SubjectSection.notes:
        return Icons.note_alt_rounded;
      case SubjectSection.aiChat:
        return Icons.smart_toy_rounded;
    }
  }
}

/// Phase 10 (AI Features): the five per-lecture actions from the plan
/// — "Explain, Summarize, Key Points, Important Questions, Generate
/// Notes" (Copy/Share aren't Gemini calls, so they're plain buttons in
/// the screen rather than entries here).
enum AiAction { explain, summarize, keyPoints, importantQuestions, generateNotes }

extension AiActionX on AiAction {
  String get label {
    switch (this) {
      case AiAction.explain:
        return 'Explain';
      case AiAction.summarize:
        return 'Summarize';
      case AiAction.keyPoints:
        return 'Key Points';
      case AiAction.importantQuestions:
        return 'Important Questions';
      case AiAction.generateNotes:
        return 'Generate Notes';
    }
  }

  IconData get icon {
    switch (this) {
      case AiAction.explain:
        return Icons.lightbulb_outline_rounded;
      case AiAction.summarize:
        return Icons.short_text_rounded;
      case AiAction.keyPoints:
        return Icons.checklist_rounded;
      case AiAction.importantQuestions:
        return Icons.quiz_outlined;
      case AiAction.generateNotes:
        return Icons.note_alt_outlined;
    }
  }

  /// The instruction sent to Gemini ahead of the lecture's OCR text.
  /// Kept short and directive — the model already gets the source text
  /// as grounding, this just says what to do with it.
  String get promptInstruction {
    switch (this) {
      case AiAction.explain:
        return 'Explain the following lecture content in simple, clear '
            'terms for a student studying it, as if teaching it from '
            'scratch. Use plain language and short paragraphs.';
      case AiAction.summarize:
        return 'Summarize the following lecture content into a concise '
            'summary a student could review in under a minute. Keep the '
            'core ideas, drop filler.';
      case AiAction.keyPoints:
        return 'Extract the key points from the following lecture '
            'content as a short bulleted list. Each bullet should be one '
            'self-contained idea.';
      case AiAction.importantQuestions:
        return 'Based on the following lecture content, write a list of '
            'likely exam-style important questions a student should be '
            'able to answer, covering the main concepts.';
      case AiAction.generateNotes:
        return 'Turn the following lecture content into clean, '
            'well-organized study notes with headings and bullet points, '
            'suitable for revision later.';
    }
  }
}

/// Phase 16 (Settings — "Theme"): the person's choice, as opposed to
/// Flutter's `ThemeMode` which is what actually gets applied — kept as
/// a separate enum so it can be stored in Isar via `@enumerated`
/// without depending on Flutter's own enum staying stable.
enum ThemePreference { system, light, dark }

extension ThemePreferenceX on ThemePreference {
  String get label {
    switch (this) {
      case ThemePreference.system:
        return 'System';
      case ThemePreference.light:
        return 'Light';
      case ThemePreference.dark:
        return 'Dark';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }
}

/// Phase 16 (Settings — "OCR Language"): ML Kit's on-device recognizer
/// is script-based rather than language-based — one recognizer covers
/// every language written in that script (Latin covers English,
/// Spanish, French, Vietnamese, ...; Devanagari covers Hindi, Marathi,
/// Nepali, ...). Offered as scripts rather than a long language list so
/// the option actually matches what ML Kit can do.
enum OcrScript { latin, chinese, devanagari, japanese, korean }

extension OcrScriptX on OcrScript {
  String get label {
    switch (this) {
      case OcrScript.latin:
        return 'Latin (English & most European languages)';
      case OcrScript.chinese:
        return 'Chinese';
      case OcrScript.devanagari:
        return 'Devanagari (Hindi, Marathi, ...)';
      case OcrScript.japanese:
        return 'Japanese';
      case OcrScript.korean:
        return 'Korean';
    }
  }
}

/// Phase 11 (Subject AI Chat): who sent a given [ChatMessage] — the
/// person or Gemini's reply.
enum ChatRole { user, assistant }

/// The fixed, deliberately small allow-list of things the global
/// assistant (the floating bubble) can actually *do* in the app, on
/// top of just replying — e.g. "switch to dark mode" or "open DBMS".
/// Gemini names one of these in its structured reply;
/// `AssistantActionDispatcher` is the only place that turns it into a
/// real app change. Nothing outside this list (no free-form code, no
/// destructive actions like deleting a subject) is ever exposed to it.
enum AssistantActionType { none, setTheme, navigateTab, openSubject }

/// Phase 14 (Assignment Manager): whether an uploaded assignment has
/// been turned in yet. "Overdue" isn't stored — it's derived on
/// [Assignment.isOverdue] from status + deadline, so it's never stale.
enum AssignmentStatus { pending, submitted }

extension AssignmentStatusX on AssignmentStatus {
  String get label {
    switch (this) {
      case AssignmentStatus.pending:
        return 'Pending';
      case AssignmentStatus.submitted:
        return 'Submitted';
    }
  }
}

/// A file uploaded through the Resource Manager (Phase 6). PPT/Word have
/// no text extractor yet (the plan calls this out as "later"), so only
/// pdf/image resources get `extractedText` populated for now.
enum ResourceType { pdf, ppt, word, image }

extension ResourceTypeX on ResourceType {
  String get label {
    switch (this) {
      case ResourceType.pdf:
        return 'PDF';
      case ResourceType.ppt:
        return 'PPT';
      case ResourceType.word:
        return 'Word';
      case ResourceType.image:
        return 'Image';
    }
  }

  /// Subfolder name under `Subject/Resources/` on disk.
  String get folderName {
    switch (this) {
      case ResourceType.pdf:
        return 'PDFs';
      case ResourceType.ppt:
        return 'PPTs';
      case ResourceType.word:
        return 'Word';
      case ResourceType.image:
        return 'Images';
    }
  }

  /// Whether this type currently supports automatic text extraction.
  bool get supportsExtraction =>
      this == ResourceType.pdf || this == ResourceType.image;

  /// Detects the type from a file's extension. Returns null for
  /// anything outside PDF/PPT/Word/Image — the upload flow skips those.
  static ResourceType? fromExtension(String path) {
    final ext = path.toLowerCase().contains('.')
        ? path.toLowerCase().split('.').last
        : '';
    switch (ext) {
      case 'pdf':
        return ResourceType.pdf;
      case 'ppt':
      case 'pptx':
        return ResourceType.ppt;
      case 'doc':
      case 'docx':
        return ResourceType.word;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'webp':
        return ResourceType.image;
      default:
        return null;
    }
  }
}