import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/enums.dart';
import 'api_key_service.dart';

/// Thrown when a Gemini call is attempted before a key has been saved
/// in Settings. Screens catch this specifically to send the person to
/// Settings rather than showing a generic error.
class GeminiApiKeyMissingException implements Exception {
  @override
  String toString() => 'No Gemini API key set';
}

/// Thrown for any other failure — bad key, network error, non-200
/// response, or an unexpected response shape.
class GeminiApiException implements Exception {
  GeminiApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Phase 10 — AI Features: "Each lecture gets Explain / Summarize / Key
/// Points / Important Questions / Generate Notes. Gemini reads OCR
/// text." This is the ONLY place in the app that calls the Gemini API
/// — screens never build the HTTP request themselves, the same
/// separation `TextExtractionService` keeps for ML Kit/PDF text.
///
/// Reused as-is by Phase 11 (Subject AI Chat), which just assembles a
/// different prompt (lecture + PDFs + PPTs + syllabus context) and
/// calls [generateRaw] directly instead of going through an [AiAction].
class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  /// Flash model: fast and cheap enough for per-lecture actions the
  /// person might tap several times per lecture. Kept as one constant
  /// so it's a single-line change if a different model is preferred.
  static const _model = 'gemini-2.5-flash';

  static Uri _endpoint(String apiKey) => Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/'
        '$_model:generateContent?key=$apiKey',
      );

  /// Runs one of the five per-lecture [AiAction]s against [sourceText]
  /// (the lecture's OCR text, per the plan). Throws
  /// [GeminiApiKeyMissingException] if Settings has no key saved yet,
  /// or [GeminiApiException] for any other failure.
  Future<String> runAction({
    required AiAction action,
    required String sourceText,
  }) {
    final prompt = '${action.promptInstruction}\n\n'
        '--- Lecture content ---\n$sourceText';
    return generateRaw(prompt);
  }

  /// Lower-level entry point: sends [prompt] to Gemini as-is and
  /// returns the text response. Used directly by [runAction] above and,
  /// from Phase 11 onward, by the subject-wide AI chat.
  Future<String> generateRaw(String prompt) async {
    final apiKey = await ApiKeyService.instance.getKey();
    if (apiKey == null) throw GeminiApiKeyMissingException();

    final http.Response response;
    try {
      response = await http.post(
        _endpoint(apiKey),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );
    } catch (e) {
      throw GeminiApiException('Could not reach Gemini: $e');
    }

    if (response.statusCode != 200) {
      throw GeminiApiException(
        _errorMessageFrom(response.statusCode, response.body),
      );
    }

    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = decoded['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        throw GeminiApiException('Gemini returned no response.');
      }
      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List?;
      final text = parts
          ?.map((p) => (p as Map<String, dynamic>)['text'] as String? ?? '')
          .join();
      if (text == null || text.trim().isEmpty) {
        throw GeminiApiException('Gemini returned an empty response.');
      }
      return text.trim();
    } on GeminiApiException {
      rethrow;
    } catch (e) {
      throw GeminiApiException('Could not read Gemini\'s response: $e');
    }
  }

  String _errorMessageFrom(int statusCode, String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = (decoded['error'] as Map<String, dynamic>?)?['message'];
      if (message is String && message.isNotEmpty) {
        return 'Gemini error ($statusCode): $message';
      }
    } catch (_) {
      // Body wasn't the expected JSON shape — fall through to the
      // generic message below rather than surfacing a parse error.
    }
    if (statusCode == 400) return 'Gemini rejected the request — check the API key in Settings.';
    if (statusCode == 403) return 'Gemini API key was rejected. Check it in Settings.';
    if (statusCode == 429) return 'Gemini rate limit hit — try again in a moment.';
    return 'Gemini request failed ($statusCode).';
  }
}
