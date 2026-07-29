import 'enums.dart';

/// One instruction the global assistant chose to act on, parsed out of
/// Gemini's structured JSON reply (see `GlobalAssistantService`).
///
/// [value] is the type-specific target and means different things per
/// [type]:
/// - [AssistantActionType.setTheme]: "light" | "dark" | "system"
/// - [AssistantActionType.navigateTab]: a tab label, e.g. "Settings"
/// - [AssistantActionType.openSubject]: a subject name or code
/// - [AssistantActionType.none]: unused, always null
///
/// `AssistantActionDispatcher` is the only place that reads this and
/// turns it into a real app change.
class AssistantAction {
  const AssistantAction({required this.type, this.value});

  final AssistantActionType type;
  final String? value;

  static const none = AssistantAction(type: AssistantActionType.none);
}