import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/models/app_settings.dart';
import '../core/models/enums.dart';
import '../core/services/api_key_service.dart';
import '../core/services/backup_service.dart';
import '../core/services/settings_service.dart';
import '../providers/settings_provider.dart';
import '../utils/constants.dart';

/// Settings — the plan's exact list: "Gemini API Key, OCR Language,
/// Theme, Export Database, Import Database, Backup Folder, Clear
/// Cache." The API key row was pulled forward to Phase 10 since AI
/// features needed it to function; everything else here is genuinely
/// new in Phase 16.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _apiKeyController = TextEditingController();
  bool _obscureKey = true;
  bool _loadingKey = true;
  bool _savingKey = false;
  bool _hasSavedKey = false;

  bool _backingUp = false;
  bool _clearingCache = false;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final key = await ApiKeyService.instance.getKey();
    if (!mounted) return;
    setState(() {
      _hasSavedKey = key != null;
      _apiKeyController.text = key ?? '';
      _loadingKey = false;
    });
  }

  Future<void> _saveApiKey() async {
    final value = _apiKeyController.text.trim();
    if (value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a key before saving.')),
      );
      return;
    }
    setState(() => _savingKey = true);
    await ApiKeyService.instance.setKey(value);
    if (!mounted) return;
    setState(() {
      _savingKey = false;
      _hasSavedKey = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key saved')),
    );
  }

  Future<void> _clearApiKey() async {
    await ApiKeyService.instance.clearKey();
    if (!mounted) return;
    setState(() {
      _apiKeyController.clear();
      _hasSavedKey = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gemini API key removed')),
    );
  }

  Future<void> _pickOcrScript(OcrScript current) async {
    final chosen = await showModalBottomSheet<OcrScript>(
      context: context,
      builder: (context) => SafeArea(
        child: RadioGroup<OcrScript>(
          groupValue: current,
          onChanged: (value) => Navigator.of(context).pop(value),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final script in OcrScript.values)
                RadioListTile<OcrScript>(
                  value: script,
                  title: Text(script.label),
                ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null && chosen != current) {
      await SettingsService.instance.setOcrScript(chosen);
    }
  }

  Future<void> _exportDatabase() async {
    try {
      await BackupService.instance.shareExportedDatabase();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _importDatabase() async {
    final file = await BackupService.instance.pickDatabaseFile();
    if (file == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Replace current data?'),
        content: const Text(
          'This replaces every semester, subject, lecture, and file '
          "record with what's in the selected backup. This can't be "
          'undone unless you have another backup of the current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _importing = true);
    try {
      await BackupService.instance.importDatabase(file);
      if (mounted) {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Import complete'),
            content: const Text(
              'Close Academic Assistant completely and reopen it for the '
              'imported data to load.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _chooseBackupFolder() async {
    final path = await BackupService.instance.chooseBackupFolder();
    if (path == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup folder set')),
    );
  }

  Future<void> _backUpNow(String folderPath) async {
    setState(() => _backingUp = true);
    try {
      final count = await BackupService.instance.backupNow(folderPath);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backed up $count files')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Backup failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _backingUp = false);
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'Removes temporary files only — your subjects, lectures, and '
          'documents are stored separately and are never touched by '
          'this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingCache = true);
    try {
      final freed = await BackupService.instance.clearCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cleared ${_formatBytes(freed)}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not clear cache: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _clearingCache = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loadingKey
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppConstants.spaceM),
              children: [
                // --- Gemini API Key (Phase 10) ---
                Text('Gemini API Key', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  'Needed for AI features — Explain, Summarize, Key '
                  'Points, and Subject AI Chat. Stored securely on this '
                  'device only, never synced anywhere.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.spaceM),
                TextField(
                  controller: _apiKeyController,
                  obscureText: _obscureKey,
                  decoration: InputDecoration(
                    hintText: 'Paste your Gemini API key',
                    suffixIcon: IconButton(
                      icon: Icon(_obscureKey
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureKey = !_obscureKey),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.spaceS),
                Row(
                  children: [
                    if (_hasSavedKey)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(Icons.check_circle_rounded,
                            size: 16, color: theme.colorScheme.primary),
                      ),
                    Text(
                      _hasSavedKey
                          ? 'Key saved on this device'
                          : 'No key saved yet',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.spaceM),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _savingKey ? null : _saveApiKey,
                        child: Text(_savingKey ? 'Saving…' : 'Save Key'),
                      ),
                    ),
                    if (_hasSavedKey) ...[
                      const SizedBox(width: AppConstants.spaceS),
                      OutlinedButton(
                        onPressed: _clearApiKey,
                        child: const Text('Remove'),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: AppConstants.spaceXL),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: AppConstants.spaceM),

                // --- Theme ---
                Text('Theme', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spaceS),
                SegmentedButton<ThemePreference>(
                  segments: [
                    for (final pref in ThemePreference.values)
                      ButtonSegment(value: pref, label: Text(pref.label)),
                  ],
                  selected: {
                    context.watch<SettingsProvider>().themePreference
                  },
                  onSelectionChanged: (selection) {
                    SettingsService.instance
                        .setThemePreference(selection.first);
                  },
                ),

                const SizedBox(height: AppConstants.spaceXL),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: AppConstants.spaceM),

                // --- OCR Language, Backup Folder (live settings row) ---
                StreamBuilder<AppSettings>(
                  stream: SettingsService.instance.watch(),
                  builder: (context, snapshot) {
                    final settings = snapshot.data;
                    final ocrScript = settings?.ocrScript ?? OcrScript.latin;
                    final backupFolder = settings?.backupFolderPath;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('OCR Language',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppConstants.spaceXS),
                        Text(
                          'ML Kit recognizes text by script, not by '
                          'individual language — pick whichever covers '
                          "your lectures' handwriting/print.",
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppConstants.spaceS),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.translate_rounded),
                          title: Text(ocrScript.label),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => _pickOcrScript(ocrScript),
                        ),
                        const SizedBox(height: AppConstants.spaceL),
                        Text('Backup Folder',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: AppConstants.spaceXS),
                        Text(
                          'A full copy of every subject\'s files plus the '
                          'database — stays on this device or wherever '
                          'you point it (an SD card, a synced folder, '
                          "etc.), never Anthropic's or Google's servers.",
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                        const SizedBox(height: AppConstants.spaceS),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.folder_outlined),
                          title: Text(backupFolder ?? 'Not set'),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: _chooseBackupFolder,
                        ),
                        const SizedBox(height: AppConstants.spaceS),
                        FilledButton.icon(
                          onPressed: (backupFolder == null || _backingUp)
                              ? null
                              : () => _backUpNow(backupFolder),
                          icon: _backingUp
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.backup_outlined),
                          label:
                              Text(_backingUp ? 'Backing up…' : 'Back Up Now'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: AppConstants.spaceXL),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: AppConstants.spaceM),

                // --- Export / Import Database ---
                Text('Export Database', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  'Save just the database (semesters, subjects, '
                  'timetable, notes) as one file, to move it to another '
                  'device or keep a quick snapshot.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.spaceS),
                OutlinedButton.icon(
                  onPressed: _exportDatabase,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: const Text('Export Database'),
                ),
                const SizedBox(height: AppConstants.spaceL),
                Text('Import Database', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  'Replaces all current data with a previously exported '
                  'file. The app needs to be closed and reopened '
                  'afterward.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.spaceS),
                OutlinedButton.icon(
                  onPressed: _importing ? null : _importDatabase,
                  icon: _importing
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_importing ? 'Importing…' : 'Import Database'),
                ),

                const SizedBox(height: AppConstants.spaceXL),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: AppConstants.spaceM),

                // --- Clear Cache ---
                Text('Clear Cache', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppConstants.spaceXS),
                Text(
                  "Frees temporary space the OS set aside for this app. "
                  "Doesn't touch any subject, lecture, or document — "
                  'those live in a separate, permanent folder.',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppConstants.spaceS),
                OutlinedButton.icon(
                  onPressed: _clearingCache ? null : _clearCache,
                  icon: _clearingCache
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cleaning_services_outlined),
                  label:
                      Text(_clearingCache ? 'Clearing…' : 'Clear Cache'),
                ),
              ],
            ),
    );
  }
}
