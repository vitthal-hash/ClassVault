import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/isar_service.dart';
import 'file_storage_service.dart';
import 'settings_service.dart';

/// Phase 16 (Settings): "Export Database, Import Database, Backup
/// Folder, Clear Cache." No new packages needed — `file_picker`
/// (Phase 3), `path_provider` (Phase 1), and `share_plus` (Phase 10)
/// already cover everything here.
class BackupService {
  BackupService._();
  static final BackupService instance = BackupService._();

  static const _dbFileName = 'academic_assistant_db.isar';

  /// Copies the live Isar database to a temp file and hands it to the
  /// OS share sheet — the person picks where it ends up (Drive, Files,
  /// email, another device over AirDrop/Nearby Share, ...). Uses Isar's
  /// own `copyToFile`, which is safe to call on a database that's
  /// still open, rather than copying the raw file underneath it.
  Future<void> shareExportedDatabase() async {
    final tempDir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final destPath = '${tempDir.path}/academic_assistant_backup_$stamp.isar';

    await IsarService.instance.db.copyToFile(destPath);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(destPath)],
        subject: 'Academic Assistant backup',
        text: 'Academic Assistant database backup — import this from '
            'Settings on the destination device.',
      ),
    );
  }

  /// Lets the person pick a previously-exported `.isar` file. Returns
  /// null if they cancel.
  Future<File?> pickDatabaseFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['isar'],
    );
    final path = result?.files.single.path;
    return path == null ? null : File(path);
  }

  /// Replaces the live database with [source]. The Isar instance has to
  /// close first (Isar doesn't support hot-swapping the file underneath
  /// an open instance), so the caller must tell the person to close and
  /// reopen the app afterward — there's no safe way to reinitialize
  /// mid-session without every screen's already-loaded data going
  /// stale.
  Future<void> importDatabase(File source) async {
    final docs = await getApplicationDocumentsDirectory();
    final destPath = '${docs.path}/$_dbFileName';

    await IsarService.instance.close();
    await source.copy(destPath);
    // Deliberately not reopening here — see doc comment above.
  }

  /// Opens the OS folder picker and saves the choice. Returns null if
  /// the person cancels.
  Future<String?> chooseBackupFolder() async {
    final path = await FilePicker.platform.getDirectoryPath();
    if (path == null) return null;
    await SettingsService.instance.setBackupFolderPath(path);
    return path;
  }

  /// Copies every file under the app's local root (every subject's
  /// photos, PDFs, PPTs, ...) plus a fresh database snapshot into a
  /// timestamped folder inside [folderPath] — a full, human-browsable
  /// backup, matching the plan's "everything readable if you browse
  /// the files" even for backups. Returns how many files were copied.
  Future<int> backupNow(String folderPath) async {
    final root = await FileStorageService.instance.rootDir();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    final destRoot = Directory('$folderPath/AcademicAssistant_backup_$stamp');
    await destRoot.create(recursive: true);

    var fileCount = 0;
    if (await root.exists()) {
      await for (final entity in root.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          final relative = entity.path.substring(root.path.length);
          final destFile = File('${destRoot.path}$relative');
          await destFile.parent.create(recursive: true);
          await entity.copy(destFile.path);
          fileCount++;
        }
      }
    }

    await IsarService.instance.db.copyToFile('${destRoot.path}/$_dbFileName');
    fileCount++;

    return fileCount;
  }

  /// Clears the OS-managed temp/cache directory only — never the
  /// documents folder everything else in this app lives in, so this
  /// can never delete a subject's actual files. Returns bytes freed.
  Future<int> clearCache() async {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) return 0;

    var freedBytes = 0;
    await for (final entity in tempDir.list(followLinks: false)) {
      try {
        if (entity is File) {
          freedBytes += await entity.length();
          await entity.delete();
        } else if (entity is Directory) {
          freedBytes += await _dirSize(entity);
          await entity.delete(recursive: true);
        }
      } catch (_) {
        // Some temp entries may be locked/in-use (e.g. a picker mid
        // operation) — skip rather than fail the whole clear.
      }
    }
    return freedBytes;
  }

  Future<int> _dirSize(Directory dir) async {
    var total = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {
          // Ignore unreadable entries when estimating size.
        }
      }
    }
    return total;
  }
}