import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/app_settings.dart';
import '../core/models/enums.dart';
import '../core/services/settings_service.dart';

/// Exists mainly so `MaterialApp.themeMode` can react live to the
/// Settings screen's Theme picker — everything else Settings touches
/// (OCR script, backup folder) is read directly from `SettingsService`
/// where it's used instead of duplicated here.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider() {
    _sub = SettingsService.instance.watch().listen((settings) {
      _themePreference = settings.themePreference;
      notifyListeners();
    });
  }

  ThemePreference _themePreference = ThemePreference.system;
  ThemePreference get themePreference => _themePreference;
  ThemeMode get themeMode => _themePreference.themeMode;

  late final StreamSubscription<AppSettings> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
