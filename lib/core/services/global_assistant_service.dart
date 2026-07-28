import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';
import 'gemini_service.dart';

/// Sentinel `subjectId` reserved for the global ClassVault bot's thread.
/// [ChatMessage] is otherwise always scoped to one real subject; real
/// subjects are `Isar.autoIncrement` starting at 1, so a negative id
/// can never collide with one. Reusing the existing collection (rather
/// than adding a new Isar `@collection`) avoids a schema migration for
/// what is, structurally, the exact same "who said what, when" shape.
const int kGlobalAssistantSubjectId = -1;

/// The floating "ClassVault" bubble's brain — available from every
/// screen, unlike [ChatService] which only ever answers about one
/// subject's own uploaded material. This one is deliberately NOT
/// grounded in any subject's files: it's a general study helper (explain
/// a concept, work through a problem, suggest how to revise), not a
/// document Q&A tool. It's also deliberately restricted to study/
/// academic topics — see [_systemPrompt] — and always answers in
/// character as "ClassVault," never as "Gemini" or a generic assistant.
class GlobalAssistantService {
  GlobalAssistantService._();
  static final GlobalAssistantService instance = GlobalAssistantService._();

  static const _historyTurns = 12;

  Isar get _db => IsarService.instance.db;

  Stream<List<ChatMessage>> watchMessages() {
    return _db.chatMessages
        .filter()
        .subjectIdEqualTo(kGlobalAssistantSubjectId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  Future<String> sendMessage(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return '';

    await _addMessage(ChatRole.user, trimmed);

    final history = await watchMessages().first;
    final recentHistory = history.length > _historyTurns
        ? history.sublist(history.length - _historyTurns)
        : history;

    final answer = await GeminiService.instance.generateRaw(
      _buildPrompt(recentHistory),
    );
    await _addMessage(ChatRole.assistant, answer);
    return answer;
  }

  String _buildPrompt(List<ChatMessage> history) {
    final buffer = StringBuffer()..writeln(_systemPrompt);

    if (history.isNotEmpty) {
      buffer.writeln('\n--- Conversation so far ---');
      for (final message in history) {
        final speaker = message.role == ChatRole.user ? 'Student' : 'You';
        buffer.writeln('$speaker: ${message.content}');
      }
      buffer.writeln('--- end of conversation ---');
    }

    return buffer.toString();
  }

  static const _systemPrompt =
      'You are "ClassVault," the built-in study assistant of the ClassVault '
      'app. Always speak as ClassVault in the first person — never call '
      'yourself Gemini, an AI language model, or anything else, and never '
      'break character.\n\n'
      'Scope: you only help with study and academic topics — explaining '
      'concepts, working through problems, exam/assignment prep, study '
      'strategies, and questions about how to use ClassVault itself. If '
      'someone asks something outside that (general chit-chat, news, '
      'personal advice unrelated to studying, etc.), briefly and politely '
      'decline and steer them back to study help — do not answer the '
      'off-topic question first.\n\n'
      'Your replies are read aloud by text-to-speech, so write the way you '
      'would actually talk: short sentences, no markdown, no bullet points '
      'or numbered lists, no headers, and no asterisks or symbols used for '
      'emphasis. Keep answers reasonably concise unless the student asks '
      'for a full walkthrough.';

  Future<void> _addMessage(ChatRole role, String content) async {
    final message = ChatMessage()
      ..subjectId = kGlobalAssistantSubjectId
      ..role = role
      ..content = content
      ..createdAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.chatMessages.put(message);
    });
  }

  Future<void> clearHistory() async {
    await _db.writeTxn(() async {
      await _db.chatMessages
          .filter()
          .subjectIdEqualTo(kGlobalAssistantSubjectId)
          .deleteAll();
    });
  }
}