import 'package:isar/isar.dart';

import 'enums.dart';

part 'chat_message.g.dart';

/// One turn in a subject's AI chat (Phase 11): "Instead of chatting with
/// all files, chat only with DBMS." Every message belongs to exactly
/// one subject — there's no cross-subject thread among real subjects.
///
/// One exception: [kGlobalAssistantSubjectId] (a negative sentinel,
/// defined in `global_assistant_service.dart`) reuses this same
/// collection for the floating "ClassVault" bot's thread, which isn't
/// tied to any subject. Real subjects are `Isar.autoIncrement` starting
/// at 1, so the sentinel can never collide with one.
///
/// Only user/assistant turns that actually completed are stored here —
/// a failed Gemini call shows an inline error in the chat screen (same
/// pattern as Phase 10's per-lecture AI actions) but isn't written to
/// this collection, so a retry never resends a broken exchange back to
/// Gemini as history.
@collection
class ChatMessage {
  Id id = Isar.autoIncrement;

  @Index()
  late int subjectId;

  @Index()
  @enumerated
  late ChatRole role;

  late String content;

  @Index()
  DateTime createdAt = DateTime.now();
}