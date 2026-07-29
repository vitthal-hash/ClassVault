import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../main.dart' show navigatorKey;
import '../../providers/nav_provider.dart';
import '../../screens/semester_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/subject_workspace_screen.dart';
import '../models/assistant_action.dart';
import '../models/enums.dart';
import '../models/subject.dart';
import 'semester_service.dart';
import 'settings_service.dart';
import 'subject_service.dart';

/// Carries out an [AssistantAction] the global assistant decided on —
/// e.g. actually switching the theme or navigating to a tab/subject.
///
/// This is deliberately the ONLY place in the app that turns an
/// assistant reply into a real change: [GlobalAssistantService] just
/// parses what Gemini asked for, it never touches settings or
/// navigation itself. The action types it can receive are the fixed
/// allow-list in [AssistantActionType] — nothing destructive (deleting
/// a subject, clearing data, etc.) is ever exposed to the assistant.
///
/// Uses the app-wide `navigatorKey` rather than requiring a
/// `BuildContext` to be threaded in, since this runs from
/// `ClassVaultBotScreen` after the Gemini call returns, not from a
/// widget's build method.
class AssistantActionDispatcher {
  AssistantActionDispatcher._();

  static const _tabIndexByLabel = {
    'home': 0,
    'subjects': 1,
    'ai chat': 2,
    'search': 3,
  };

  /// Runs [action]. Returns a short message to show the student (e.g.
  /// via a SnackBar) when something needs surfacing beyond what the
  /// assistant already said out loud — such as not finding a subject —
  /// or null when the action either succeeded silently or was
  /// [AssistantActionType.none].
  static Future<String?> run(AssistantAction action) async {
    switch (action.type) {
      case AssistantActionType.none:
        return null;
      case AssistantActionType.setTheme:
        return _setTheme(action.value);
      case AssistantActionType.navigateTab:
        return _navigateTab(action.value);
      case AssistantActionType.openSubject:
        return _openSubject(action.value);
    }
  }

  static Future<String?> _setTheme(String? value) async {
    final preference = switch (value?.trim().toLowerCase()) {
      'light' => ThemePreference.light,
      'dark' => ThemePreference.dark,
      'system' => ThemePreference.system,
      _ => null,
    };
    if (preference == null) return null;
    await SettingsService.instance.setThemePreference(preference);
    // No follow-up message — the assistant's own spoken reply already
    // confirms this ("Switched to dark mode").
    return null;
  }

  static Future<String?> _navigateTab(String? value) async {
    final label = value?.trim().toLowerCase();
    if (label == null) return null;

    final context = navigatorKey.currentContext;
    if (context == null) return null;

    // Semester and Settings aren't tabs anymore (see RootShell's
    // "More" sheet) — push them directly instead of going through
    // NavProvider.
    if (label == 'semester') {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const SemesterScreen()),
      );
      return null;
    }
    if (label == 'settings') {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
      navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
      );
      return null;
    }

    final index = _tabIndexByLabel[label];
    if (index == null) return null;

    // Whatever screen the bubble was opened on top of (this chat
    // screen itself, or a subject workspace) is a route pushed above
    // RootShell — pop back down to it first or the tab switch happens
    // underneath the current screen, invisibly.
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    context.read<NavProvider>().setIndex(index);
    return null;
  }

  static Future<String?> _openSubject(String? value) async {
    final needle = value?.trim().toLowerCase();
    if (needle == null || needle.isEmpty) return null;

    final semester = await SemesterService.instance.getActive();
    if (semester == null) {
      return 'There\'s no active semester set up to look for subjects in.';
    }

    final subjects =
        await SubjectService.instance.getForSemester(semester.id);
    final subject = _findSubject(subjects, needle);
    if (subject == null) {
      return 'Couldn\'t find a subject called "$value".';
    }

    navigatorKey.currentState?.popUntil((route) => route.isFirst);
    navigatorKey.currentState?.push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectWorkspaceScreen(subject: subject),
      ),
    );
    return null;
  }

  /// Exact name/code match first, then falls back to a substring match
  /// so "open dbms lab notes" still finds a subject named "DBMS".
  static Subject? _findSubject(List<Subject> subjects, String needle) {
    for (final subject in subjects) {
      if (subject.name.toLowerCase() == needle ||
          subject.code?.toLowerCase() == needle) {
        return subject;
      }
    }
    for (final subject in subjects) {
      if (subject.name.toLowerCase().contains(needle)) return subject;
    }
    return null;
  }
}