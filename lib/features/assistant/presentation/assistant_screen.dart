import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/chat_bubble.dart';
import '../../auth/application/auth_controller.dart';
import '../data/assistant_repository.dart';

/// A single turn in the companion conversation. Beyond role/content it can
/// carry the RAG sources, a suggested in-app action, and follow-up questions
/// that live turns return (history turns only have role/content).
class _Msg {
  final String role;
  final String content;
  final List<String> sources;
  final AssistantAction? action;
  final List<String> followups;
  final bool hasImage;
  _Msg(this.role, this.content, {this.sources = const [], this.action, this.followups = const [], this.hasImage = false});
}

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({super.key});

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final _input = TextEditingController();
  final _scrollController = ScrollController();
  final List<_Msg> _messages = [];
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
      if (mounted) setState(() => _messages.addAll(history.map((m) => _Msg(m.role, m.content))));
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

  Future<void> _send({String? preset}) async {
    final question = (preset ?? _input.text).trim();
    if (question.isEmpty || _sending) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);

    setState(() {
      _messages.add(_Msg('user', question));
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();

    try {
      final r = await ref.read(assistantRepositoryProvider).ask(userId: userId, question: question, language: language);
      setState(() => _messages.add(_Msg('assistant', r.answer, sources: r.sources, action: r.action, followups: r.followups)));
    } catch (e) {
      setState(() => _messages.add(_Msg('assistant', extractError(e))));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  Future<void> _sendImage(ImageSource source) async {
    if (_sending) return;
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 85, maxWidth: 2000);
    if (picked == null) return;
    final question = _input.text.trim();

    setState(() {
      _messages.add(_Msg('user', question.isEmpty ? '🖼️' : question, hasImage: true));
      _sending = true;
      _input.clear();
    });
    _scrollToBottom();

    try {
      final r = await ref.read(assistantRepositoryProvider).askImage(userId: userId, question: question, language: language, imagePath: picked.path);
      setState(() => _messages.add(_Msg('assistant', r.answer, action: r.action, followups: r.followups)));
    } catch (e) {
      setState(() => _messages.add(_Msg('assistant', extractError(e))));
    } finally {
      setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _pickImageSource() {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.read(languageProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(Icons.photo_camera_rounded, color: colors.primary),
            title: Text(t('assistant.image.camera', language), style: TextStyle(color: colors.text)),
            onTap: () { Navigator.pop(context); _sendImage(ImageSource.camera); },
          ),
          ListTile(
            leading: Icon(Icons.image_rounded, color: colors.primary),
            title: Text(t('assistant.image.gallery', language), style: TextStyle(color: colors.text)),
            onTap: () { Navigator.pop(context); _sendImage(ImageSource.gallery); },
          ),
        ]),
      ),
    );
  }

  /// Maps a backend action href to the closest in-app route and navigates.
  void _runAction(String href) {
    const map = {
      '/dashboard': '/home',
      '/skills': '/skills',
      '/skills/progress': '/skills/profile',
      '/course': '/course',
      '/studio': '/studio',
      '/ielts': '/skills',
      '/sat': '/skills',
      '/sat/planner': '/skills',
    };
    var target = '/home';
    for (final entry in map.entries) {
      if (href == entry.key || href.startsWith('${entry.key}?') || href.startsWith('${entry.key}/')) {
        target = entry.value;
        break;
      }
    }
    context.push(target);
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
                          return _buildMessage(_messages[i], colors, language);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.add_photo_alternate_rounded, color: colors.primary),
                    tooltip: t('assistant.image.attach', language),
                    onPressed: _sending ? null : _pickImageSource,
                  ),
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
                    child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20), onPressed: _sending ? null : () => _send()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(_Msg m, ThemeColors colors, String language) {
    final isUser = m.role == 'user';
    if (isUser) {
      return ChatBubble(isUser: true, content: m.content, colors: colors);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChatBubble(isUser: false, content: m.content, citations: m.sources.isEmpty ? null : m.sources, colors: colors),
        if (m.action != null)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 4),
            child: OutlinedButton.icon(
              onPressed: () => _runAction(m.action!.href),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: Text(m.action!.label),
            ),
          ),
        if (m.followups.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6, right: 40),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: m.followups
                  .map((f) => ActionChip(
                        label: Text(f, style: TextStyle(color: colors.text, fontSize: 12.5)),
                        backgroundColor: colors.card,
                        side: BorderSide(color: colors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onPressed: _sending ? null : () => _send(preset: f),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
