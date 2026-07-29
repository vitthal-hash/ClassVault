import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/isar_service.dart';
import 'core/services/note_service.dart';
import 'core/services/reminder_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/nav_provider.dart';
import 'providers/semester_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/root_shell.dart';
import 'utils/constants.dart';
import 'widgets/classvault_bubble_overlay.dart';
import 'widgets/note_editor_sheet.dart';

// Handle to the app's real Navigator, reachable from anywhere — including
// widgets like ClassVaultBubbleOverlay that live outside the Navigator's
// own subtree (see the builder below) and so can't use Navigator.of(context).
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bring Isar up before the app renders so every screen can safely
  // assume the database is ready.
  await IsarService.instance.init();

  // Phase 17 (Reminders): stand up notifications before the first
  // frame so a note/assignment saved on the very first screen can
  // schedule successfully.
  await ReminderService.instance.init();
  ReminderService.onNoteReminderTapped = (noteId) async {
    final note = await NoteService.instance.getById(noteId);
    // Fetched fresh right here (after the await), not a context stashed
    // before it — there's no State/mounted to check against since this
    // callback lives outside any widget, so the lint's stale-context
    // concern doesn't actually apply.
    // ignore: use_build_context_synchronously
    final context = navigatorKey.currentContext;
    if (note != null && context != null) {
      NoteEditorSheet.showEdit(context, note: note);
    }
  };

  runApp(const AcademicAssistantApp());
}

class AcademicAssistantApp extends StatelessWidget {
  const AcademicAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavProvider()),
        ChangeNotifierProvider(create: (_) => SemesterProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: navigatorKey,
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          home: const RootShell(),
          // Floats the ClassVault bubble above whatever route is
          // currently showing — main tabs or any pushed screen alike —
          // rather than wiring it into every screen individually.
          builder: (context, child) => Stack(
            children: [
              if (child != null) child,
              const ClassVaultBubbleOverlay(),
            ],
          ),
        ),
      ),
    );
  }
}