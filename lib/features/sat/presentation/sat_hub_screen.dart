import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../data/sat_models.dart';
import '../data/sat_repository.dart';
import 'sat_practice_screen.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class SatHubScreen extends ConsumerStatefulWidget {
  const SatHubScreen({super.key});
  @override
  ConsumerState<SatHubScreen> createState() => _SatHubScreenState();
}

class _SatHubScreenState extends ConsumerState<SatHubScreen> {
  SatScore? _score;
  SatSkillTree? _tree;
  String? _error;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final repo = ref.read(satRepositoryProvider);
      final results = await Future.wait([repo.score(userId), repo.skillTree(userId)]);
      if (mounted) setState(() { _score = results[0] as SatScore; _tree = results[1] as SatSkillTree; });
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    }
  }

  void _practice({String? domain, String? skill, required String title}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => SatPracticeScreen(title: title, domain: domain, skill: skill),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0, iconTheme: IconThemeData(color: colors.text),
        title: Text(_tr(lang, 'SAT tayyorgarlik', 'Подготовка к SAT', 'SAT Preparation'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800)),
      ),
      body: _error != null
          ? Center(child: Text(_tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'), style: TextStyle(color: colors.textSecondary)))
          : _tree == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Score card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]), borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tr(lang, 'Bashorat qilingan ball', 'Прогноз балла', 'Predicted score'), style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(_score?.predictedScore != null ? '${_score!.predictedScore}' : '—', style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w900)),
                          const Text('/ 1600', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ]),
                        const Spacer(),
                        const Icon(Icons.school_rounded, color: Colors.white38, size: 56),
                      ]),
                    ),
                    if (_score != null && !_score!.available && _score!.message != null)
                      Padding(padding: const EdgeInsets.only(top: 8), child: Text(
                        _tr(lang, 'Ballni ochish uchun bir nechta mashq sessiyasini yakunlang.', 'Пройдите несколько сессий, чтобы открыть прогноз.', _score!.message!),
                        style: TextStyle(color: colors.textSecondary, fontSize: 12))),
                    const SizedBox(height: 16),
                    // Quick practice
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _practice(title: _tr(lang, 'Tezkor mashq', 'Быстрая практика', 'Quick practice')),
                        style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(_tr(lang, 'Tezkor mashq (10 savol)', 'Быстрая практика (10)', 'Quick practice (10 questions)'), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(_tr(lang, 'Savollar banki', 'Банк вопросов', 'Question bank'), style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(_tr(lang, 'Ko\'nikma bo\'yicha mashq qiling', 'Практикуйтесь по навыкам', 'Practice by skill'), style: TextStyle(color: colors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 12),
                    ..._tree!.sections.expand((sec) => [
                          if (sec.section.isNotEmpty)
                            Padding(padding: const EdgeInsets.only(top: 6, bottom: 8),
                                child: Text(sec.section, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.4))),
                          ...sec.domains.map((d) => _DomainTile(domain: d, lang: lang, onTapDomain: () => _practice(domain: d.domain, title: d.domain), onTapSkill: (sk) => _practice(domain: d.domain, skill: sk, title: sk))),
                        ]),
                  ],
                ),
    );
  }
}

class _DomainTile extends StatefulWidget {
  final SatDomain domain;
  final String lang;
  final VoidCallback onTapDomain;
  final void Function(String skill) onTapSkill;
  const _DomainTile({required this.domain, required this.lang, required this.onTapDomain, required this.onTapSkill});
  @override
  State<_DomainTile> createState() => _DomainTileState();
}

class _DomainTileState extends State<_DomainTile> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final d = widget.domain;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Column(children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.domain, style: TextStyle(color: colors.text, fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(value: d.accuracy, minHeight: 5, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(colors.success)),
                  ),
                  const SizedBox(height: 4),
                  Text('${d.attempted}/${d.questionCount} · ${(d.accuracy * 100).round()}% ${_tr(widget.lang, 'to\'g\'ri', 'верно', 'correct')}',
                      style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                ]),
              ),
              const SizedBox(width: 8),
              Icon(_open ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: colors.textSecondary),
            ]),
          ),
        ),
        if (_open) ...[
          Divider(height: 1, color: colors.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Column(children: [
              InkWell(
                onTap: widget.onTapDomain,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(children: [
                    Icon(Icons.shuffle_rounded, size: 16, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(_tr(widget.lang, 'Butun bo\'lim bo\'yicha mashq', 'Практика всего раздела', 'Practice whole domain'), style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
              ...d.skills.map((sk) => InkWell(
                    onTap: () => widget.onTapSkill(sk.skill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(children: [
                        Expanded(child: Text(sk.skill, style: TextStyle(color: colors.text, fontSize: 13))),
                        Text('${(sk.accuracy * 100).round()}%', style: TextStyle(color: colors.textSecondary, fontSize: 11)),
                        const SizedBox(width: 6),
                        Icon(Icons.chevron_right_rounded, size: 18, color: colors.textSecondary),
                      ]),
                    ),
                  )),
            ]),
          ),
        ],
      ]),
    );
  }
}
