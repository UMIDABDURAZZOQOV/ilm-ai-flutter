import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_loading.dart';
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('chat.title', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        actions: [
          AnimatedPressable(
            onTap: _messages.isEmpty ? null : _confirmClear,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _messages.isEmpty ? colors.border.withValues(alpha: 0.3) : colors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_outline_rounded, color: _messages.isEmpty ? colors.textMuted : colors.error, size: 22),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingHistory
                ? const Center(child: PremiumLoading())
                : _messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: colors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(Icons.chat_bubble_outline_rounded, size: 40, color: colors.primary),
                              ),
                              const SizedBox(height: 16),
                              Text(t('chat.no.materials', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textSecondary, fontSize: 15, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(20),
                        itemCount: _messages.length + (_sending ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i == _messages.length) {
                            return Align(
                              alignment: Alignment.centerLeft,
                              child: PremiumCard(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(16),
                                borderRadius: 20,
                                child: const PremiumLoading(size: 24),
                              ),
                            );
                          }
                          final m = _messages[i];
                          return ChatBubble(isUser: m.role == 'user', content: m.content, citations: m.citations, colors: colors).animate().fadeIn(delay: (i * 50).ms, duration: 300.ms);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: t('chat.placeholder', language),
                        hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
                        filled: true,
                        fillColor: colors.inputBackground,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AnimatedPressable(
                    onTap: _sending ? null : _send,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _sending 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
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
