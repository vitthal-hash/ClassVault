import 'package:flutter/material.dart';

import '../core/models/subject.dart';
import 'subject_tabs/ai_chat_tab.dart';

/// Hosts [AiChatTab] with its own app bar, for the one place it's
/// opened outside the Subject Workspace's tab bar: the top-level "AI
/// Chat" nav destination, which picks a subject first (see
/// [AiChatScreen]) and then needs a full screen to open it into.
class SubjectChatScreen extends StatelessWidget {
  const SubjectChatScreen({super.key, required this.subject});

  final Subject subject;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${subject.name} · AI Chat')),
      body: AiChatTab(subject: subject),
    );
  }
}
