import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Phase 10 / Phase 16 (Settings — "Gemini API Key"): stores the
/// person's Gemini API key using the platform keystore/keychain via
/// `flutter_secure_storage`, rather than in Isar, which writes plain
/// files to app storage. Everything else in this app is deliberately
/// plaintext-on-disk ("everything readable if you browse the files"
/// per the plan) — the API key is the one thing that shouldn't be.
class ApiKeyService {
  ApiKeyService._();
  static final ApiKeyService instance = ApiKeyService._();

  static const _key = 'gemini_api_key';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  Future<String?> getKey() async {
    final value = await _storage.read(key: _key);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<void> setKey(String value) => _storage.write(key: _key, value: value.trim());

  Future<void> clearKey() => _storage.delete(key: _key);

  Future<bool> get hasKey async => (await getKey()) != null;
}
