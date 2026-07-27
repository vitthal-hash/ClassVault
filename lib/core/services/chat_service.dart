import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';
import '../models/subject.dart';
import 'chat_context_service.dart';
import 'gemini_service.dart';

/// Phase 11 — Subject AI Chat: "Explain BCNF -> Gemini searches Lecture
/// + PDF + PPT + Syllabus -> Answer." Owns the chat's message history
/// and the prompt assembly around each new question; the actual Gemini
/// HTTP call still goes through [GeminiService.generateRaw] (Phase
/// 10's one entry point to the API), and gathering the subject's
/// grounding text is [ChatContextService]'s job.
class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  Isar get _db => IsarService.instance.db;

  /// How many previous turns (user + assistant messages combined) are
  /// sent back to Gemini as conversation history alongside the fresh
  /// context block. Keeps follow-up questions ("what about the second
  /// one?") working without re-sending the whole chat on every turn.
  static const _historyTurns = 12;

  Stream<List<ChatMessage>> watchMessages(int subjectId) {
    return _db.chatMessages
        .filter()
        .subjectIdEqualTo(subjectId)
        .sortByCreatedAt()
        .watch(fireImmediately: true);
  }

  /// Sends [question] for [subject]: stores the user's turn right
  /// away, asks Gemini with the subject's full context + recent
  /// history in front of it, then stores the reply. Rethrows on
  /// failure (same [GeminiApiKeyMissingException] /
  /// [GeminiApiException] pair Phase 10 uses) after the user's message
  /// is already saved, so the question stays visible in the thread and
  /// the screen can offer to retry without retyping it.
  Future<void> sendMessage({
    required Subject subject,
    required String question,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    await _addMessage(subjectId: subject.id, role: ChatRole.user, content: trimmed);

    final context = await ChatContextService.instance.buildContext(subject);
    final history = await watchMessages(subject.id).first;
    final recentHistory = history.length > _historyTurns
        ? history.sublist(history.length - _historyTurns)
        : history;

    final prompt = _buildPrompt(
      subjectName: subject.name,
      context: context,
      history: recentHistory,
    );

    final answer = await GeminiService.instance.generateRaw(prompt);
    await _addMessage(
      subjectId: subject.id,
      role: ChatRole.assistant,
      content: answer,
    );
  }

  String _buildPrompt({
    required String subjectName,
    required String context,
    required List<ChatMessage> history,
  }) {
    final buffer = StringBuffer()
      ..writeln(
        'You are a study assistant helping a student with their '
        '"$subjectName" course. Answer using the subject material below '
        'when it\'s relevant; if the material doesn\'t cover the '
        'question, say so and answer from general knowledge instead. '
        'Keep answers clear and student-friendly.',
      );

    if (context.isEmpty) {
      buffer.writeln(
        '\nNo lecture, resource, or syllabus text has been uploaded for '
        'this subject yet.',
      );
    } else {
      buffer
        ..writeln('\n--- $subjectName material ---')
        ..writeln(context)
        ..writeln('--- end of material ---');
    }

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

  Future<void> _addMessage({
    required int subjectId,
    required ChatRole role,
    required String content,
  }) async {
    final message = ChatMessage()
      ..subjectId = subjectId
      ..role = role
      ..content = content
      ..createdAt = DateTime.now();
    await _db.writeTxn(() async {
      await _db.chatMessages.put(message);
    });
  }

  Future<void> clearHistory(int subjectId) async {
    await _db.writeTxn(() async {
      await _db.chatMessages.filter().subjectIdEqualTo(subjectId).deleteAll();
    });
  }
}
