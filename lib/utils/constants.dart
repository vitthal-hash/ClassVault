import 'package:flutter/material.dart';

/// App-wide constants used across every phase.
class AppConstants {
  AppConstants._();

  static const String appName = 'Academic Assistant';

  // Local storage root (mirrors the plan's folder structure):
  // AcademicAssistant/Semester_X/Subject/Theory|Lab|.../...
  static const String rootFolderName = 'AcademicAssistant';

  // Standard spacing scale — keep every screen visually consistent.
  static const double spaceXS = 4;
  static const double spaceS = 8;
  static const double spaceM = 16;
  static const double spaceL = 24;
  static const double spaceXL = 32;

  static const double radiusM = 14;
  static const double radiusL = 20;
}

/// Section types inside a subject workspace (used from Phase 4 onward).
enum SubjectSection {
  theory,
  lab,
  tutorial,
  resources,
  lectures,
  assignments,
  syllabus,
  aiChat,
  notes,
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
      case SubjectSection.aiChat:
        return 'AI Chat';
      case SubjectSection.notes:
        return 'Notes';
    }
  }

  IconData get icon {
    switch (this) {
      case SubjectSection.theory:
        return Icons.menu_book_outlined;
      case SubjectSection.lab:
        return Icons.science_outlined;
      case SubjectSection.tutorial:
        return Icons.groups_outlined;
      case SubjectSection.resources:
        return Icons.folder_outlined;
      case SubjectSection.lectures:
        return Icons.photo_camera_outlined;
      case SubjectSection.assignments:
        return Icons.assignment_outlined;
      case SubjectSection.syllabus:
        return Icons.description_outlined;
      case SubjectSection.aiChat:
        return Icons.smart_toy_outlined;
      case SubjectSection.notes:
        return Icons.sticky_note_2_outlined;
    }
  }

  /// Which phase (from the master plan) builds this tab's real content.
  /// All sections are built as of this update — this stays around as a
  /// safety net in case a future section is added ahead of its tab.
  int? get buildsInPhase {
    switch (this) {
      case SubjectSection.theory:
      case SubjectSection.lab:
      case SubjectSection.tutorial:
      case SubjectSection.syllabus:
      case SubjectSection.resources:
      case SubjectSection.lectures:
      case SubjectSection.assignments:
      case SubjectSection.aiChat:
      case SubjectSection.notes:
        return null; // built already, no placeholder needed
    }
  }
}