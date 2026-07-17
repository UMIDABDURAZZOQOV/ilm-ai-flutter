import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../auth/application/auth_controller.dart';
import '../data/chat_models.dart';
import '../data/chat_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _sending = false;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final history = await ref.read(chatRepositoryProvider).getHistory(userId);
      if (mounted) setState(() => _messages.addAll(history));
    } catch (_) {
      // history is best-effort
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  @override
  void dispose() {
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final question = _input.text.trim();
    if (question.isEmpty || _sending) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: question));
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();

    try {
      final res = await ref.read(chatRepositoryProvider).ask(userId: userId, question: question, language: language);
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: res.answer, citations: res.citations)));
    } catch (e) {
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: extractError(e))));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _confirmClear() async {
    final language = ref.read(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('chat.clear', language)),
        content: Text(t('chat.clear.confirm', language)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(t('common.cancel', language))),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(t('common.confirm', language), style: TextStyle(color: colors.error))),
        ],
      ),
    );
    if (confirmed == true) {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        try {
          await ref.read(chatRepositoryProvider).clearHistory(userId);
        } catch (_) {}
      }
      setState(() => _messages.clear());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('chat.title', language)),
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _messages.isEmpty ? null : _confirmClear),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(t('chat.no.materials', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted)),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary)),
                              ),
                            );
                          }
                          final m = _messages[i];
                          return ChatBubble(isUser: m.role == 'user', content: m.content, citations: m.citations, colors: colors);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: t('chat.placeholder', language),
                        filled: true,
                        fillColor: colors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedPressable(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.secondary]), shape: BoxShape.circle),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
