import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/database/isar_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/nav_provider.dart';
import 'providers/semester_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/root_shell.dart';
import 'utils/constants.dart';
import 'widgets/classvault_bubble_overlay.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bring Isar up before the app renders so every screen can safely
  // assume the database is ready.
  await IsarService.instance.init();

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