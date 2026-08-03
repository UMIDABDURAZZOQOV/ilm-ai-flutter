import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/animated_pressable.dart';
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
        title: Text(_tr(lang, 'SAT tayyorgarlik', 'Подготовка к SAT', 'SAT Preparation'), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: _error != null
          ? Center(child: Text(_tr(lang, 'Yuklab bo\'lmadi.', 'Не удалось загрузить.', 'Failed to load.'), style: TextStyle(color: colors.textSecondary)))
          : _tree == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Score card
                    PremiumGradientCard(
                      padding: const EdgeInsets.all(24),
                      gradientColors: [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
                      borderRadius: 24,
                      child: Row(children: [
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_tr(lang, 'Bashorat qilingan ball', 'Прогноз балла', 'Predicted score'), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(_score?.predictedScore != null ? '${_score!.predictedScore}' : '—', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900, letterSpacing: -2)),
                          const Text('/ 1600', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                        ]),
                        const Spacer(),
                        const Icon(Icons.school_rounded, color: Colors.white38, size: 64),
                      ]),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    if (_score != null && !_score!.available && _score!.message != null)
                      Padding(padding: const EdgeInsets.only(top: 12), child: Text(
                        _tr(lang, 'Ballni ochish uchun bir nechta mashq sessiyasini yakunlang.', 'Пройдите несколько сессий, чтобы открыть прогноз.', _score!.message!),
                        style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500))),
                    const SizedBox(height: 20),
                    // Quick practice
                    PremiumButton(
                      onPressed: () => _practice(title: _tr(lang, 'Tezkor mashq', 'Быстрая практика', 'Quick practice')),
                      borderRadius: 20,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded),
                          const SizedBox(width: 8),
                          Text(_tr(lang, 'Tezkor mashq (10 savol)', 'Быстрая практика (10)', 'Quick practice (10 questions)'), style: const TextStyle(fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ).animate().fadeIn(delay: 100.ms, duration: 350.ms),
                    const SizedBox(height: 24),
                    Text(_tr(lang, 'Savollar banki', 'Банк вопросов', 'Question bank'), style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                    const SizedBox(height: 6),
                    Text(_tr(lang, 'Ko\'nikma bo\'yicha mashq qiling', 'Практикуйтесь по навыкам', 'Practice by skill'), style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 16),
                    ..._tree!.sections.asMap().entries.map((entry) {
                      final secIndex = entry.key;
                      final sec = entry.value;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (sec.section.isNotEmpty)
                            Padding(padding: const EdgeInsets.only(top: 8, bottom: 12),
                                child: Text(sec.section, style: TextStyle(color: colors.textSecondary, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.4))),
                          ...sec.domains.asMap().entries.map((domainEntry) {
                            final domainIndex = domainEntry.key;
                            final d = domainEntry.value;
                            return _DomainTile(
                              domain: d,
                              lang: lang,
                              onTapDomain: () => _practice(domain: d.domain, title: d.domain),
                              onTapSkill: (sk) => _practice(domain: d.domain, skill: sk, title: sk),
                            ).animate().fadeIn(delay: (150 + (secIndex * 50) + (domainIndex * 30)).ms, duration: 350.ms).slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
                          }),
                        ],
                      );
                    }),
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
    return PremiumCard(
      margin: const EdgeInsets.only(bottom: 14),
      borderRadius: 20,
      padding: const EdgeInsets.all(18),
      child: Column(children: [
        AnimatedPressable(
          onTap: () => setState(() => _open = !_open),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(d.domain, style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.3)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: d.accuracy, minHeight: 6, backgroundColor: colors.border, valueColor: AlwaysStoppedAnimation(colors.success)),
                ),
                const SizedBox(height: 6),
                Text('${d.attempted}/${d.questionCount} · ${(d.accuracy * 100).round()}% ${_tr(widget.lang, 'to\'g\'ri', 'верно', 'correct')}',
                    style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(width: 12),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: colors.textSecondary, size: 24),
            ),
          ]),
        ),
        if (_open) ...[
          const SizedBox(height: 12),
          Divider(height: 1, color: colors.border),
          const SizedBox(height: 8),
          Column(children: [
            AnimatedPressable(
              onTap: widget.onTapDomain,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: colors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.shuffle_rounded, size: 18, color: colors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(_tr(widget.lang, 'Butun bo\'lim bo\'yicha mashq', 'Практика всего раздела', 'Practice whole domain'), style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
            ...d.skills.map((sk) => AnimatedPressable(
                  onTap: () => widget.onTapSkill(sk.skill),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(child: Text(sk.skill, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w500))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: colors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text('${(sk.accuracy * 100).round()}%', style: TextStyle(color: colors.success, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.chevron_right_rounded, size: 20, color: colors.textSecondary),
                    ]),
                  ),
                )),
          ]),
        ],
      ]),
    );
  }
}
