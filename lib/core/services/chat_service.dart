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
  /// history in front of it, then stores the reply and returns its
  /// text (so the screen can speak it). Rethrows on failure (same
  /// [GeminiApiKeyMissingException] / [GeminiApiException] pair Phase
  /// 10 uses) after the user's message is already saved, so the
  /// question stays visible in the thread and the screen can offer to
  /// retry without retyping it.
  Future<String> sendMessage({
    required Subject subject,
    required String question,
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return '';

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
    return answer;
  }

  /// Runs one of the five [AiAction]s (Explain/Summarize/Key Points/
  /// Important Questions/Generate Notes) against EVERYTHING uploaded
  /// so far for [subject] — lectures, resources, syllabus, and notes —
  /// rather than a single lecture's OCR text the way the per-lecture
  /// actions elsewhere in the app do. Logged into the same chat thread
  /// as a normal turn, so it stays visible and part of the
  /// conversation history for follow-up questions. Returns the reply
  /// text so the screen can speak it.
  Future<String> runSubjectAction({
    required Subject subject,
    required AiAction action,
  }) async {
    await _addMessage(
      subjectId: subject.id,
      role: ChatRole.user,
      content: '${action.label} — using everything uploaded for '
          '${subject.name} so far.',
    );

    final context = await ChatContextService.instance.buildContext(subject);
    if (context.isEmpty) {
      const reply = 'Nothing\'s been uploaded for this subject yet — add '
          'a lecture, resource, syllabus, or note first and I can work '
          'from that.';
      await _addMessage(
        subjectId: subject.id,
        role: ChatRole.assistant,
        content: reply,
      );
      return reply;
    }

    final prompt = '${action.promptInstruction}\n\n'
        'Base this on everything uploaded so far for "${subject.name}" — '
        'lectures, resources, the syllabus, and notes — not just one '
        'item, and pull together material from across all of them where '
        'relevant. Write it the way you\'d say it out loud: no markdown, '
        'no bullet or numbered lists, no headers or asterisks — plain '
        'spoken sentences, since this may be read aloud.\n\n'
        '--- ${subject.name} material ---\n$context\n--- end of material ---';

    final answer = await GeminiService.instance.generateRaw(prompt);
    await _addMessage(
      subjectId: subject.id,
      role: ChatRole.assistant,
      content: answer,
    );
    return answer;
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
        'Keep answers clear, student-friendly, and reasonably concise. '
        'Your replies may be read aloud by text-to-speech, so write the '
        'way you\'d actually talk: no markdown, no bullet or numbered '
        'lists, no headers, and no asterisks used for emphasis.',
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