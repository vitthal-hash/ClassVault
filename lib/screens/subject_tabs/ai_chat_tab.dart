import 'package:flutter/material.dart';

import '../../core/models/chat_message.dart';
import '../../core/models/enums.dart';
import '../../core/models/subject.dart';
import '../../core/services/chat_service.dart';
import '../../core/services/gemini_service.dart';
import '../../utils/constants.dart';
import '../../widgets/placeholder_view.dart';
import '../settings_screen.dart';

/// AI Chat tab (Phase 11): "Instead of chatting with all files, chat
/// only with DBMS." Gemini is grounded on this subject's lecture OCR,
/// resource text, and syllabus (assembled by [ChatContextService]) plus
/// the recent turns of this same thread — a fresh conversation, scoped
/// to exactly this subject, every time it's opened.
///
/// Also used, unchanged, as the body of the top-level "AI Chat" nav
/// tab's per-subject screen — this widget owns the whole chat
/// experience so there's only one implementation to keep in sync with
/// [ChatService].
class AiChatTab extends StatefulWidget {
  const AiChatTab({super.key, required this.subject});

  final Subject subject;

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _sending = false;
  String? _error;
  bool _errorIsKeyMissing = false;

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    _controller.clear();
    setState(() {
      _sending = true;
      _error = null;
      _errorIsKeyMissing = false;
    });

    try {
      await ChatService.instance.sendMessage(
        subject: widget.subject,
        question: text,
      );
      _scrollToBottom();
    } on GeminiApiKeyMissingException {
      if (mounted) {
        setState(() {
          _errorIsKeyMissing = true;
          _error = 'No Gemini API key set yet. Add one in Settings to '
              'start chatting.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: Text(
          'This deletes this conversation about ${widget.subject.name}. '
          'The lectures, resources, and syllabus it\'s grounded on are '
          'untouched.',
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
    if (confirmed == true) {
      await ChatService.instance.clearHistory(widget.subject.id);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatMessage>>(
      stream: ChatService.instance.watchMessages(widget.subject.id),
      builder: (context, snapshot) {
        final messages = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(child: _buildMessageArea(messages)),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: _TypingIndicator(),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: _ErrorBanner(
                  message: _error!,
                  showSettingsLink: _errorIsKeyMissing,
                ),
              ),
            _buildInputBar(hasHistory: messages.isNotEmpty),
          ],
        );
      },
    );
  }

  Widget _buildMessageArea(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return PlaceholderView(
        icon: Icons.smart_toy_outlined,
        title: 'Chat with ${widget.subject.name}',
        subtitle:
            'Ask about anything from this subject\'s lectures, '
            'resources, or syllabus — Gemini answers using what '
            'you\'ve uploaded here.',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
    );
  }

  Widget _buildInputBar({required bool hasHistory}) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Clear chat',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: hasHistory ? _confirmClear : null,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Ask about ${widget.subject.name}…',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppConstants.radiusL),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : _send,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == ChatRole.user;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppConstants.radiusM),
      topRight: const Radius.circular(AppConstants.radiusM),
      bottomLeft: Radius.circular(isUser ? AppConstants.radiusM : 4),
      bottomRight: Radius.circular(isUser ? 4 : AppConstants.radiusM),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: radius,
        ),
        child: SelectableText(
          message.content,
          style: TextStyle(
            color: isUser
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Thinking…', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.showSettingsLink});

  final String message;
  final bool showSettingsLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                if (showSettingsLink) ...[
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    child: const Text('Open Settings'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}