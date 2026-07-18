import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

class ParentDashboardScreen extends ConsumerStatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  ConsumerState<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends ConsumerState<ParentDashboardScreen> {
  bool _loading = true;
  List<ChildDetail> _children = [];
  FamilyCodeInfo? _codeInfo;
  final _linkCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(skillExtrasRepositoryProvider);
      _children = await repo.getChildren();
      _codeInfo = await repo.getFamilyCode();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _toast(String msg) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _link() async {
    final lang = ref.read(languageProvider);
    if (_linkCtrl.text.trim().isEmpty) return;
    setState(() => _busy = true);
    try {
      final r = await ref.read(skillExtrasRepositoryProvider).linkChild(_linkCtrl.text.trim());
      _linkCtrl.clear();
      await _load();
      _toast(r['already'] == true
          ? str3(lang, "Allaqachon bog'langan", 'Уже привязан', 'Already linked')
          : str3(lang, "${r['child_name']} bilan bog'landingiz", 'Вы привязаны к ${r['child_name']}', 'Linked to ${r['child_name']}'));
    } catch (_) {
      _toast(str3(lang, "Kod noto'g'ri", 'Неверный код', 'Invalid code'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    return Scaffold(
      appBar: AppBar(title: Text(str3(lang, 'Ota-ona paneli', 'Родительская панель', 'Parent dashboard'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(str3(lang, 'Farzandlarim', 'Мои дети', 'My children'), style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (_children.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text(str3(lang, "Hali bog'lanmagan. Farzand kodini kiriting.", 'Пока никого. Введите код ребёнка.', "None yet. Enter your child's code."), style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center)),
                  ),
                for (final c in _children) _childCard(lang, c),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(str3(lang, 'Farzandni bog\'lash', 'Привязать ребёнка', 'Link a child'), style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(str3(lang, 'Farzandingiz ilovasidagi 6 xonali kodni kiriting.', 'Введите 6-значный код из приложения ребёнка.', "Enter the 6-char code from your child's app."), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: _linkCtrl, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(hintText: 'ABC123', isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))),
                      const SizedBox(width: 8),
                      FilledButton(style: FilledButton.styleFrom(backgroundColor: const Color(0xFFF03E3E)), onPressed: _busy ? null : _link, child: Text(str3(lang, "Bog'lash", 'Привязать', 'Link'))),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                if (_codeInfo != null)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(colors: [Color(0xFFF03E3E), Color(0xFFE64980)]),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(str3(lang, 'Ota-onangizga beradigan kodingiz', 'Ваш код для родителя', 'Your code to share with a parent'), style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text(_codeInfo!.code, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _codeInfo!.code));
                            _toast(str3(lang, 'Nusxalandi', 'Скопировано', 'Copied'));
                          },
                          icon: const Icon(Icons.copy_rounded, color: Colors.white),
                        ),
                      ]),
                      if (_codeInfo!.linkedParentNames.isNotEmpty)
                        Text('${str3(lang, 'Bog\'langan:', 'Привязан:', 'Linked:')} ${_codeInfo!.linkedParentNames.join(', ')}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ]),
                  ),
              ],
            ),
    );
  }

  Widget _childCard(String lang, ChildDetail c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            CircleAvatar(radius: 22, backgroundColor: const Color(0xFFF06595).withValues(alpha: 0.2), child: Text(c.name.isNotEmpty ? c.name[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE64980)))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                Text(
                  c.activeToday
                      ? str3(lang, "Bugun o'qidi ✓", 'Занимался сегодня ✓', 'Studied today ✓')
                      : c.lastActive != null
                          ? '${str3(lang, 'Oxirgi:', 'Последняя:', 'Last:')} ${c.lastActive}'
                          : str3(lang, 'Hali boshlamagan', 'Ещё не начал', 'Not started yet'),
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                ),
              ]),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(skillExtrasRepositoryProvider).unlinkChild(c.userId);
                await _load();
              },
              child: Text(str3(lang, 'Uzish', 'Отвязать', 'Unlink'), style: const TextStyle(fontSize: 12)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _stat(Icons.bolt_rounded, const Color(0xFFFFC800), '${c.xpTotal}', 'XP'),
            _stat(Icons.local_fire_department_rounded, const Color(0xFFFF9600), '${c.streakDays}', str3(lang, 'kun', 'дней', 'streak')),
            _stat(Icons.menu_book_rounded, const Color(0xFF58CC02), '${c.lessonsCompleted}', str3(lang, 'dars', 'уроков', 'lessons')),
          ]),
          if (c.strongest != null || c.weakest != null) ...[
            const SizedBox(height: 8),
            Row(children: [
              if (c.strongest != null)
                Expanded(child: _chip(str3(lang, 'Kuchli', 'Сильный', 'Strong'), c.strongest!.nameFor(lang), const Color(0xFF58CC02))),
              if (c.strongest != null && c.weakest != null && c.weakest!.slug != c.strongest!.slug) const SizedBox(width: 8),
              if (c.weakest != null && c.weakest!.slug != c.strongest?.slug)
                Expanded(child: _chip(str3(lang, 'Zaif', 'Слабый', 'Weak'), c.weakest!.nameFor(lang), const Color(0xFFFF4B4B))),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _stat(IconData icon, Color color, String value, String label) => Expanded(
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        ]),
      );

  Widget _chip(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: RichText(
          text: TextSpan(style: const TextStyle(fontSize: 11.5), children: [
            TextSpan(text: '$label: ', style: TextStyle(color: color, fontWeight: FontWeight.w800)),
            TextSpan(text: value, style: TextStyle(color: Colors.grey.shade800)),
          ]),
        ),
      );
}
