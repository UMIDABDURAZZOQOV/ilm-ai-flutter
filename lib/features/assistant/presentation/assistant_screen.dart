import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../auth/application/auth_controller.dart';
import '../../chat/data/chat_models.dart';
import '../data/assistant_repository.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
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
      final history = await ref.read(assistantRepositoryProvider).getHistory(userId);
      if (mounted) setState(() => _messages.addAll(history));
    } catch (_) {
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
      final answer = await ref.read(assistantRepositoryProvider).ask(userId: userId, question: question, language: language);
      setState(() => _messages.add(ChatMessage(role: 'assistant', content: answer)));
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
        title: Text(t('assistant.clear', language)),
        content: Text(t('assistant.clear.confirm', language)),
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
          await ref.read(assistantRepositoryProvider).clearHistory(userId);
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
        title: Text(t('assistant.title', language)),
        actions: [
          IconButton(
            icon: Icon(Icons.graphic_eq_rounded, color: colors.primary),
            tooltip: t('assistant.live.button', language),
            onPressed: () => context.push('/live-voice'),
          ),
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
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.auto_awesome, size: 40, color: colors.primary),
                              const SizedBox(height: 12),
                              Text(t('assistant.empty.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(t('assistant.empty.desc', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted)),
                            ],
                          ),
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
                          return ChatBubble(isUser: m.role == 'user', content: m.content, colors: colors);
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
                        hintText: t('assistant.placeholder', language),
                        filled: true,
                        fillColor: colors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: colors.border)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(gradient: LinearGradient(colors: [colors.primary, colors.secondary]), shape: BoxShape.circle),
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sending ? null : _send),
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
