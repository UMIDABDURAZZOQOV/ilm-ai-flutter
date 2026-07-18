import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

const _site = 'ilm-ai-edu.vercel.app';

class SkillReferralScreen extends ConsumerStatefulWidget {
  const SkillReferralScreen({super.key});

  @override
  ConsumerState<SkillReferralScreen> createState() => _SkillReferralScreenState();
}

class _SkillReferralScreenState extends ConsumerState<SkillReferralScreen> {
  bool _loading = true;
  ReferralInfo? _info;
  final _codeCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      _info = await ref.read(skillExtrasRepositoryProvider).getReferral(userId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _apply() async {
    final lang = ref.read(languageProvider);
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _codeCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(skillExtrasRepositoryProvider).applyReferral(userId, _codeCtrl.text.trim());
      _codeCtrl.clear();
      await _load();
      _toast(str3(lang, "+${r['bonus_xp']} XP! Sizni ${r['inviter_name']} taklif qildi.", '+${r['bonus_xp']} XP! Вас пригласил(а) ${r['inviter_name']}.', '+${r['bonus_xp']} XP! Invited by ${r['inviter_name']}.'));
    } catch (_) {
      _toast(str3(lang, "Kod noto'g'ri yoki allaqachon ishlatilgan", 'Неверный или уже использованный код', 'Invalid or already-used code'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final info = _info;
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, "Do'st taklif qilish", 'Пригласить друга', 'Invite a friend'))),
      body: _loading || info == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(colors: [Color(0xFFF06595), Color(0xFFE64980)]),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(str3(lang, 'Sizning taklif kodingiz', 'Ваш код приглашения', 'Your invite code'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(info.code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: info.code));
                          _toast(str3(lang, 'Nusxalandi', 'Скопировано', 'Copied'));
                        },
                        icon: const Icon(Icons.copy_rounded, color: Colors.white),
                      ),
                    ]),
                    Text(
                      str3(lang, "Har bir do'st = ikkalangizga ham +${info.bonusPerInvite} XP", 'Каждый друг = +${info.bonusPerInvite} XP вам обоим', 'Each friend = +${info.bonusPerInvite} XP for you both'),
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ]),
                ),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _stat('${info.invitedCount}', str3(lang, 'Taklif qilingan', 'Приглашено', 'Invited'), const Color(0xFFF06595))),
                  const SizedBox(width: 10),
                  Expanded(child: _stat('+${info.bonusEarned}', 'XP', const Color(0xFFFFC800))),
                ]),
                const SizedBox(height: 14),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1CB0F6), padding: const EdgeInsets.symmetric(vertical: 14)),
                  onPressed: () {
                    final text = str3(
                      lang,
                      "Ilm AI'da men bilan Milliy Sertifikatga tayyorlan! Kodim: ${info.code}",
                      'Присоединяйся ко мне в Ilm AI! Код: ${info.code}',
                      'Join me on Ilm AI! Code: ${info.code}',
                    );
                    final url = Uri.parse('https://t.me/share/url?url=https://$_site&text=${Uri.encodeComponent(text)}');
                    launchUrl(url, mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: Text(str3(lang, "Telegram'da ulashish", 'Поделиться в Telegram', 'Share on Telegram'), style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(str3(lang, "Do'stingizning kodi bormi?", 'Есть код друга?', "Have a friend's code?"), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: _codeCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'ABC123', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 8),
                      FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF06595)), onPressed: _busy ? null : _apply, child: Text(str3(lang, 'Kiritish', 'Ввести', 'Apply'))),
                    ]),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _stat(String value, String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]),
      );
}
