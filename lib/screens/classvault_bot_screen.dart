import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../core/models/chat_message.dart';
import '../core/models/enums.dart';
import '../core/services/gemini_service.dart';
import '../core/services/global_assistant_service.dart';
import '../core/theme/app_tokens.dart';
import '../widgets/placeholder_view.dart';
import 'settings_screen.dart';

/// The floating bubble's destination. A general study helper — NOT
/// grounded in any subject's uploaded material (that's what the
/// per-subject AI Chat tab is for) — reachable from anywhere in the
/// app without leaving whatever screen you're on.
///
/// Every reply is spoken aloud automatically (flutter_tts) and the mic
/// button lets you ask by voice (speech_to_text) instead of typing —
/// tap once to start listening, it sends automatically when you stop
/// talking.
class ClassVaultBotScreen extends StatefulWidget {
  const ClassVaultBotScreen({super.key});

  @override
  State<ClassVaultBotScreen> createState() => _ClassVaultBotScreenState();
}

class _ClassVaultBotScreenState extends State<ClassVaultBotScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _speech = stt.SpeechToText();
  final _tts = FlutterTts();

  bool _sending = false;
  bool _listening = false;
  bool _speechAvailable = false;
  bool _speaking = false;
  String? _error;
  bool _errorIsKeyMissing = false;

  @override
  void initState() {
    super.initState();
    _initVoice();
  }

  Future<void> _initVoice() async {
    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.48);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _speaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    _tts.setCancelHandler(() {
      if (mounted) setState(() => _speaking = false);
    });
    if (mounted) setState(() => _speechAvailable = available);
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Voice input isn\'t available — check the microphone '
            'permission for ClassVault in your device settings.',
          ),
        ),
      );
      return;
    }

    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }

    // A person talking to a voice assistant expects it to just answer
    // when they stop talking, not to also tap send — so a completed
    // recognition sends immediately rather than only filling the field.
    setState(() => _listening = true);
    await _speech.listen(
      onResult: (result) {
        _controller.text = result.recognizedWords;
        _controller.selection = TextSelection.collapsed(
          offset: _controller.text.length,
        );
        if (result.finalResult && result.recognizedWords.trim().isNotEmpty) {
          _send();
        }
      },
    );
  }

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
      final answer = await GlobalAssistantService.instance.sendMessage(text);
      _scrollToBottom();
      await _tts.stop();
      await _tts.speak(answer);
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
        content: const Text(
          'This deletes your conversation with ClassVault. It doesn\'t '
          'affect any subject, lecture, or file.',
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
      await GlobalAssistantService.instance.clearHistory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.primary,
              child: Icon(Icons.school_rounded,
                  size: 18, color: theme.colorScheme.onPrimary),
            ),
            const SizedBox(width: AppSpacing.xs),
            const Text('ClassVault'),
          ],
        ),
        actions: [
          if (_speaking)
            IconButton(
              tooltip: 'Stop speaking',
              icon: const Icon(Icons.volume_off_rounded),
              onPressed: () => _tts.stop(),
            ),
          IconButton(
            tooltip: 'Clear chat',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _confirmClear,
          ),
        ],
      ),
      body: StreamBuilder<List<ChatMessage>>(
        stream: GlobalAssistantService.instance.watchMessages(),
        builder: (context, snapshot) {
          final messages = snapshot.data ?? [];
          return Column(
            children: [
              Expanded(child: _buildMessageArea(messages)),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.xs),
                  child: _TypingIndicator(),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xs,
                  ),
                  child: _ErrorBanner(
                    message: _error!,
                    showSettingsLink: _errorIsKeyMissing,
                  ),
                ),
              _buildInputBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageArea(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return const PlaceholderView(
        icon: Icons.school_rounded,
        title: 'Hi, I\'m ClassVault',
        subtitle:
            'Ask me to explain a concept, help you work through a '
            'problem, or plan how to study for something — by typing '
            'or by tapping the mic. I only help with study topics, and '
            'I\'ll read my answers out loud.',
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, i) => _MessageBubble(message: messages[i]),
    );
  }

  Widget _buildInputBar() {
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: _listening ? 'Stop listening' : 'Ask by voice',
                icon: Icon(
                  _listening ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: _listening ? theme.colorScheme.error : null,
                ),
                onPressed: _toggleListening,
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText:
                        _listening ? 'Listening…' : 'Ask ClassVault…',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: AppRadius.lgRadius,
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
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
      topLeft: const Radius.circular(AppRadius.md),
      topRight: const Radius.circular(AppRadius.md),
      bottomLeft: Radius.circular(isUser ? AppRadius.md : 4),
      bottomRight: Radius.circular(isUser ? 4 : AppRadius.md),
    );

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
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
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            height: 14,
            width: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: AppSpacing.xs),
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
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: AppRadius.mdRadius,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                if (showSettingsLink) ...[
                  const SizedBox(height: AppSpacing.xs),
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