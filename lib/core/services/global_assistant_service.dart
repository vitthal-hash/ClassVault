import 'dart:convert';

import 'package:isar/isar.dart';

import '../database/isar_service.dart';
import '../models/assistant_action.dart';
import '../models/chat_message.dart';
import '../models/enums.dart';
import 'gemini_service.dart';
import 'semester_service.dart';
import 'subject_service.dart';

/// Sentinel `subjectId` reserved for the global ClassVault bot's thread.
/// [ChatMessage] is otherwise always scoped to one real subject; real
/// subjects are `Isar.autoIncrement` starting at 1, so a negative id
/// can never collide with one. Reusing the existing collection (rather
/// than adding a new Isar `@collection`) avoids a schema migration for
/// what is, structurally, the exact same "who said what, when" shape.
const int kGlobalAssistantSubjectId = -1;

/// What one turn with the global assistant produced: the spoken/shown
/// [text] plus whatever [action] (possibly [AssistantAction.none]) it
/// decided to take in the app itself.
class AssistantReply {
  const AssistantReply({required this.text, required this.action});

  final String text;
  final AssistantAction action;
}

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

  Future<AssistantReply> sendMessage(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantReply(text: '', action: AssistantAction.none);
    }

    await _addMessage(ChatRole.user, trimmed);

    final history = await watchMessages().first;
    final recentHistory = history.length > _historyTurns
        ? history.sublist(history.length - _historyTurns)
        : history;

    final subjectNames = await _currentSubjectNames();
    final raw = await GeminiService.instance.generateRaw(
      _buildPrompt(recentHistory, subjectNames),
    );

    final reply = _parseReply(raw);
    await _addMessage(ChatRole.assistant, reply.text);
    return reply;
  }

  /// Subjects in the currently active semester, used only to tell
  /// Gemini what "open <subject>" could validly refer to — it never
  /// sees anything beyond names, no uploaded material.
  Future<List<String>> _currentSubjectNames() async {
    final semester = await SemesterService.instance.getActive();
    if (semester == null) return const [];
    final subjects = await SubjectService.instance.getForSemester(semester.id);
    return subjects.map((s) => s.name).toList();
  }

  String _buildPrompt(List<ChatMessage> history, List<String> subjectNames) {
    final buffer = StringBuffer()
      ..writeln(_systemPrompt)
      ..writeln()
      ..writeln(_actionInstructions(subjectNames));

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

  /// Describes the small, fixed set of app-control actions available
  /// (see [AssistantActionType]) and the exact JSON shape to answer in.
  /// Kept deliberately narrow — no destructive actions, no free-form
  /// commands — so a bad or hallucinated response can only ever land on
  /// something harmless like `type: "none"`.
  String _actionInstructions(List<String> subjectNames) {
    final subjectsLine =
        subjectNames.isEmpty ? 'none set up yet' : subjectNames.join(', ');
    return 'You can also control the ClassVault app itself, on top of '
        'replying. Respond with ONLY a JSON object — no markdown code '
        'fences, no text before or after it — in exactly this shape:\n'
        '{"reply": "<what you say>", "action": {"type": '
        '"<none|setTheme|navigateTab|openSubject>", "value": '
        '"<target, or null>"}}\n\n'
        'Rules for "action":\n'
        '- "setTheme": use when asked to change the theme/appearance. '
        'value is "light", "dark", or "system".\n'
        '- "navigateTab": use when asked to go to / open / show one of '
        'the app\'s main sections. value is one of: Home, Semester, '
        'Subjects, AI Chat, Search, Settings.\n'
        '- "openSubject": use when asked to open a specific subject\'s '
        'workspace. value is the subject\'s name. Subjects that exist '
        'right now: $subjectsLine. If the named subject isn\'t in that '
        'list, still set the action (the app will tell the student it '
        'wasn\'t found) rather than refusing.\n'
        '- "none": use for anything else, including plain questions — '
        'value is null.\n\n'
        'Always fill "reply" with a normal, spoken-style answer '
        'regardless of the action — e.g. if asked to switch to dark '
        'mode, reply something like "Switched to dark mode" AND set '
        'the setTheme action. Never mention the JSON format itself to '
        'the student.';
  }

  /// Parses Gemini's JSON reply into text + action. Falls back to
  /// treating the whole response as plain text (action: none) if it
  /// isn't valid JSON or isn't the expected shape — a malformed
  /// response should still reach the student, not get swallowed.
  AssistantReply _parseReply(String raw) {
    try {
      var cleaned = raw.trim();
      if (cleaned.startsWith('```')) {
        cleaned = cleaned
            .replaceFirst(RegExp(r'^```(json)?', caseSensitive: false), '')
            .replaceFirst(RegExp(r'```$'), '')
            .trim();
      }

      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      final text = (decoded['reply'] as String?)?.trim();
      if (text == null || text.isEmpty) {
        return AssistantReply(text: raw.trim(), action: AssistantAction.none);
      }

      final actionMap = decoded['action'] as Map<String, dynamic>?;
      final typeName = actionMap?['type'] as String?;
      final value = actionMap?['value'] as String?;
      final type = AssistantActionType.values.firstWhere(
        (t) => t.name.toLowerCase() == typeName?.toLowerCase(),
        orElse: () => AssistantActionType.none,
      );

      return AssistantReply(
        text: text,
        action: AssistantAction(type: type, value: value),
      );
    } catch (_) {
      return AssistantReply(text: raw.trim(), action: AssistantAction.none);
    }
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