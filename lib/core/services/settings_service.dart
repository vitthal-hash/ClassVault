import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/app_settings.dart';
import '../models/enums.dart';

/// Companion to `ApiKeyService` — that one owns the Gemini API key in
/// secure storage, this one owns everything else the plan's Phase 16
/// lists: theme, OCR language, and the chosen backup folder.
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  Isar get _db => IsarService.instance.db;

  /// Fires immediately with the current row (creating it on first read
  /// if this is the very first launch), then again on every change.
  Stream<AppSettings> watch() async* {
    yield await getOrCreate();
    yield* _db.appSettings.watchObject(0).map((s) => s ?? AppSettings());
  }

  Future<AppSettings> getOrCreate() async {
    final existing = await _db.appSettings.get(0);
    if (existing != null) return existing;

    final fresh = AppSettings();
    await _db.writeTxn(() async {
      await _db.appSettings.put(fresh);
    });
    return fresh;
  }

  Future<void> setThemePreference(ThemePreference value) async {
    final settings = await getOrCreate();
    settings.themePreference = value;
    await _db.writeTxn(() async {
      await _db.appSettings.put(settings);
    });
  }

  Future<void> setOcrScript(OcrScript value) async {
    final settings = await getOrCreate();
    settings.ocrScript = value;
    await _db.writeTxn(() async {
      await _db.appSettings.put(settings);
    });
  }

  Future<void> setBackupFolderPath(String? path) async {
    final settings = await getOrCreate();
    settings.backupFolderPath = path;
    await _db.writeTxn(() async {
      await _db.appSettings.put(settings);
    });
  }
}
