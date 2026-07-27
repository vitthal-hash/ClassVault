import 'package:isar/isar.dart';

import 'enums.dart';

part 'app_settings.g.dart';

/// Singleton settings row — always `id = 0`, never a second one.
///
/// Deliberately doesn't hold the Gemini API key — that stays in
/// `flutter_secure_storage` via `ApiKeyService` (Phase 10), since it's
/// the one thing in this app that shouldn't be plaintext-on-disk.
/// Everything here is exactly the kind of setting the plan means by
/// "everything readable if you browse the files."
@collection
class AppSettings {
  Id id = 0;

  @enumerated
  ThemePreference themePreference = ThemePreference.system;

  @enumerated
  OcrScript ocrScript = OcrScript.latin;

  /// Absolute path chosen via the OS folder picker, or null if the
  /// person hasn't set one yet — "Back Up Now" is disabled until then.
  String? backupFolderPath;
}
