import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_loading.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'hearts_xp_widgets.dart';
import 'skill_practice_screen.dart';
import 'skill_ui.dart';

final _subjectsProvider = FutureProvider.autoDispose<List<SkillSubject>>((ref) async {
  return ref.read(skillTreeRepositoryProvider).getSubjects();
});

final _summaryProvider = FutureProvider.autoDispose<GamificationSummary?>((ref) async {
  final userId = ref.read(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(skillTreeRepositoryProvider).getSummary(userId);
});

class SkillsHubScreen extends ConsumerWidget {
  const SkillsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final subjectsAsync = ref.watch(_subjectsProvider);
    final summary = ref.watch(_summaryProvider).valueOrNull;

    final todayXp = summary?.todayXp ?? 0;
    final goalXp = summary?.dailyGoalXp ?? 20;
    final goalPct = goalXp == 0 ? 0.0 : (todayXp / goalXp).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('skills.dashboard.card', lang), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
        actions: [
          if (summary != null)
            Padding(padding: const EdgeInsets.only(right: 16), child: Center(child: HeartsXpHeader(summary: summary))),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_subjectsProvider);
            ref.invalidate(_summaryProvider);
          },
          child: subjectsAsync.when(
            loading: () => const Center(child: PremiumLoading()),
            error: (_, _) => ListView(children: [const SizedBox(height: 200), Center(child: Text(t('skills.error.generic', lang), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)))]),
            data: (subjects) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Daily goal
                PremiumCard(
                  borderRadius: 20,
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(str3(lang, 'Kunlik maqsad', 'Цель дня', 'Daily goal'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: colors.text)),
                          Text('$todayXp/$goalXp XP${goalPct >= 1 ? ' 🎉' : ''}',
                              style: TextStyle(fontWeight: FontWeight.w900, color: goalPct >= 1 ? const Color(0xFF58CC02) : colors.textSecondary, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(value: goalPct, minHeight: 14, color: const Color(0xFF58CC02), backgroundColor: colors.border.withValues(alpha: 0.3)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),

                _sectionLabel(str3(lang, 'Fanlar', 'Предметы', 'Subjects')),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                  children: [
                    for (final s in subjects.asMap().entries)
                      AnimatedPressable(
                        onTap: () => context.push('/skills/path', extra: s.value),
                        child: PremiumCard(
                          borderRadius: 18,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(color: skillColor(s.value.color).withValues(alpha: 0.16), shape: BoxShape.circle),
                                child: Icon(subjectIcons[s.value.slug] ?? Icons.book_rounded, color: skillColor(s.value.color), size: 24),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(s.value.nameFor(lang),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, height: 1.1, color: colors.text)),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (s.key * 50).ms, duration: 300.ms),
                  ],
                ),
                const SizedBox(height: 24),

                _sectionLabel(str3(lang, 'Yana', 'Ещё', 'More')),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.5,
                  children: _featureCards(context, ref, lang, subjects, colors),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Color(0xFF94A3B8)),
      );

  List<Widget> _featureCards(BuildContext context, WidgetRef ref, String lang, List<SkillSubject> subjects, dynamic colors) {
    final cards = <_FeatureCard>[
      _FeatureCard(Icons.event_available_rounded, const Color(0xFF58CC02), str3(lang, 'Kunlik sinov', 'Ежедневный вызов', 'Daily challenge'),
          () => context.push('/skills/practice', extra: {'mode': PracticeMode.daily})),
      _FeatureCard(Icons.edit_note_rounded, const Color(0xFFFF4B4B), str3(lang, 'Xatolar daftari', 'Ошибки', 'Mistakes'),
          () => context.push('/skills/practice', extra: {'mode': PracticeMode.mistakes})),
      _FeatureCard(Icons.bolt_rounded, const Color(0xFFFFC800), str3(lang, 'Tezlik raundi', 'Молния', 'Lightning'),
          () => context.push('/skills/practice', extra: {'mode': PracticeMode.lightning})),
      _FeatureCard(Icons.flag_rounded, const Color(0xFF7048E8), str3(lang, 'Marafon', 'Марафон', 'Marathon'),
          () => _pickSubject(context, ref, lang, subjects, '/skills/marathon')),
      _FeatureCard(Icons.school_rounded, const Color(0xFF12B886), str3(lang, 'Sinov imtihoni', 'Пробный экзамен', 'Mock exam'),
          () => _pickSubject(context, ref, lang, subjects, '/skills/mock')),
      _FeatureCard(Icons.emoji_events_rounded, const Color(0xFFFF9600), str3(lang, 'Reyting', 'Рейтинг', 'Leaderboard'),
          () => context.push('/skills/leaderboard')),
      _FeatureCard(Icons.card_giftcard_rounded, const Color(0xFFF06595), str3(lang, "Do'st taklif qilish", 'Пригласить друга', 'Invite a friend'),
          () => context.push('/skills/referral')),
      _FeatureCard(Icons.person_rounded, const Color(0xFF20C997), str3(lang, 'Mening profilim', 'Мой профиль', 'My profile'),
          () => context.push('/skills/profile')),
      _FeatureCard(Icons.military_tech_rounded, const Color(0xFFCE82FF), str3(lang, 'Yutuqlar', 'Достижения', 'Achievements'),
          () => context.push('/skills/achievements')),
      _FeatureCard(Icons.groups_rounded, const Color(0xFF4C6EF5), str3(lang, 'Sinf rejimi', 'Классы', 'Classes'),
          () => context.push('/skills/classes')),
      _FeatureCard(Icons.favorite_rounded, const Color(0xFFF03E3E), str3(lang, 'Ota-onalar uchun', 'Родителям', 'For parents'),
          () => context.push('/skills/parent')),
    ];
    return [
      for (final c in cards.asMap().entries)
        AnimatedPressable(
          onTap: c.value.onTap,
          child: PremiumCard(
            borderRadius: 18,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(color: c.value.color.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12)),
                  child: Icon(c.value.icon, color: c.value.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(c.value.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: colors.text))),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (c.key * 30).ms, duration: 300.ms),
    ];
  }

  void _pickSubject(BuildContext context, WidgetRef ref, String lang, List<SkillSubject> subjects, String route) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true, // let it grow + scroll so ALL subjects are reachable
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(str3(lang, 'Fanni tanlang', 'Выберите предмет', 'Pick a subject'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final s in subjects)
                        ActionChip(
                          avatar: Icon(subjectIcons[s.slug] ?? Icons.book_rounded, color: skillColor(s.color), size: 18),
                          label: Text(s.nameFor(lang), style: const TextStyle(fontWeight: FontWeight.w700)),
                          onPressed: () {
                            Navigator.pop(ctx);
                            context.push(route, extra: s);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;
  _FeatureCard(this.icon, this.color, this.title, this.onTap);
}
