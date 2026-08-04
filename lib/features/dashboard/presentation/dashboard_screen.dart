import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/charts/score_sparkline_painter.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/duo_icon.dart';
import '../../../core/widgets/premium_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../learning_plan/data/plan_models.dart';
import '../../learning_plan/data/plan_repository.dart';
import '../../quiz/data/quiz_models.dart';
import '../../quiz/data/quiz_repository.dart';
import '../../subscription/data/subscription_repository.dart';

final _quizStatsProvider = FutureProvider.autoDispose<QuizStats?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  try {
    return await ref.read(quizRepositoryProvider).getStats(userId);
  } catch (_) {
    return null;
  }
});

final _todayPlanProvider = FutureProvider.autoDispose<TodayPlanResponse?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  try {
    return await ref.read(planRepositoryProvider).getTodayPlan(userId);
  } catch (_) {
    return null;
  }
});

class _DashboardCard {
  final IconData icon;
  final String titleKey;
  final String descKey;
  final String location; // go_router path

  const _DashboardCard({required this.icon, required this.titleKey, required this.descKey, required this.location});
}

const _cards = [
  _DashboardCard(icon: Icons.emoji_events_rounded, titleKey: 'skills.dashboard.card', descKey: 'skills.dashboard.desc', location: '/skills'),
  _DashboardCard(icon: Icons.calculate_rounded, titleKey: 'math.dashboard.card', descKey: 'math.dashboard.desc', location: '/profile/math-solver'),
  _DashboardCard(icon: Icons.chat_bubble_rounded, titleKey: 'dashboard.chat.card', descKey: 'dashboard.chat.desc', location: '/chat'),
  _DashboardCard(icon: Icons.folder_rounded, titleKey: 'dashboard.files.card', descKey: 'dashboard.files.desc', location: '/files'),
  _DashboardCard(icon: Icons.edit_rounded, titleKey: 'dashboard.quiz.card', descKey: 'dashboard.quiz.desc', location: '/quiz'),
  _DashboardCard(icon: Icons.timer_rounded, titleKey: 'focus.card', descKey: 'focus.desc', location: '/focus'),
  _DashboardCard(icon: Icons.bar_chart_rounded, titleKey: 'insights.card', descKey: 'insights.desc', location: '/insights'),
  _DashboardCard(icon: Icons.auto_stories_rounded, titleKey: 'course.card', descKey: 'course.desc', location: '/course'),
  _DashboardCard(icon: Icons.style_rounded, titleKey: 'decks.card', descKey: 'decks.desc', location: '/decks'),
  _DashboardCard(icon: Icons.auto_awesome_rounded, titleKey: 'studio.card', descKey: 'studio.desc', location: '/studio'),
  // IELTS practice lives on the web only — long reading passages and scroll-
  // through-listening are a poor fit for a phone, so it's not surfaced in the app.
  _DashboardCard(icon: Icons.school_rounded, titleKey: 'sat.card', descKey: 'sat.desc', location: '/sat'),
  _DashboardCard(icon: Icons.menu_book_rounded, titleKey: 'vocab.card', descKey: 'vocab.desc', location: '/vocab'),
  _DashboardCard(icon: Icons.school_rounded, titleKey: 'college.dashboard.card', descKey: 'college.dashboard.desc', location: '/profile/college'),
  _DashboardCard(icon: Icons.calendar_month_rounded, titleKey: 'dashboard.plan.card', descKey: 'dashboard.plan.desc', location: '/profile/learning-plan'),
  _DashboardCard(icon: Icons.gps_fixed_rounded, titleKey: 'dashboard.gaps.card', descKey: 'dashboard.gaps.desc', location: '/profile/gaps'),
  _DashboardCard(icon: Icons.send_rounded, titleKey: 'telegram.title', descKey: 'telegram.desc', location: '/profile/telegram'),
  _DashboardCard(icon: Icons.forum_rounded, titleKey: 'feedback.card.title', descKey: 'feedback.card.desc', location: '/profile/feedback'),
];

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final isPremium = ref.watch(subscriptionStatusProvider).valueOrNull?.isPremium ?? false;
    final statsAsync = ref.watch(_quizStatsProvider);
    final todayPlanAsync = ref.watch(_todayPlanProvider);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(_quizStatsProvider);
            ref.invalidate(_todayPlanProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PremiumGradientCard(
                padding: const EdgeInsets.all(24),
                gradientColors: [colors.primary, colors.secondary],
                borderRadius: 24,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('dashboard.greeting', language), style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Text(user?.name?.isNotEmpty == true ? user!.name! : 'Learner', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isPremium ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isPremium) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFD700))),
                          Text(
                            isPremium ? t('tier.premium', language) : t('tier.free', language),
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.08, end: 0, curve: Curves.easeOutCubic),
              const SizedBox(height: 16),
              todayPlanAsync.when(
                data: (plan) {
                  if (plan == null || plan.status != 'today' || plan.day == null) return const SizedBox.shrink();
                  final day = plan.day!;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PremiumCard(
                      onTap: () => context.push('/profile/learning-plan'),
                      backgroundColor: colors.primaryLight,
                      borderColor: colors.primary.withValues(alpha: 0.3),
                      borderRadius: 20,
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: DuoIcon(Icons.today_rounded, color: colors.primary, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t('dashboard.today.title', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text, fontSize: 15)),
                                const SizedBox(height: 3),
                                Text(day.topic, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.chevron_right_rounded, color: colors.primary, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              statsAsync.when(
                data: (stats) {
                  if (stats == null || (stats.sessionsCompleted == 0 && stats.topicsCovered.isEmpty)) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(child: _PremiumStatCard(icon: Icons.local_fire_department_rounded, color: colors.warning, value: '${stats.sessionsCompleted}', label: t('quiz.stats.sessions', language), colors: colors)),
                            const SizedBox(width: 12),
                            Expanded(child: _PremiumStatCard(icon: Icons.menu_book_rounded, color: colors.secondary, value: '${stats.topicsCovered.length}', label: language == 'uz' ? 'Mavzu' : language == 'ru' ? 'Темы' : 'Topics', colors: colors)),
                            const SizedBox(width: 12),
                            Expanded(child: _PremiumStatCard(icon: Icons.trending_up_rounded, color: colors.success, value: '${stats.averageScore.round()}%', label: t('quiz.stats.avg.score', language), colors: colors)),
                          ],
                        ),
                        if (stats.scoreTrend.length > 1) ...[
                          const SizedBox(height: 16),
                          PremiumCard(
                            padding: const EdgeInsets.all(18),
                            borderRadius: 20,
                            child: ScoreSparkline(values: stats.scoreTrend.map((e) => e.scorePct).toList()),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 160.ms, duration: 350.ms).slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
              Text(t('dashboard.title', language), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.textSecondary, letterSpacing: -0.3)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, i) {
                  final card = _cards[i];
                  final tint = colors.cardTints[i % colors.cardTints.length];
                  return AnimatedPressable(
                    onTap: () {
                      // Destinations that are bottom-nav tabs must SWITCH the tab
                      // (go/goBranch) — pushing them keeps Home highlighted while
                      // showing e.g. Chat, which looked broken. Non-tab screens
                      // (skills, studio, focus, profile sub-pages…) are pushed.
                      const tabRoots = {'/home', '/chat', '/assistant', '/files', '/quiz', '/profile'};
                      if (tabRoots.contains(card.location)) {
                        context.go(card.location);
                      } else {
                        context.push(card.location);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: tint.bg,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: tint.border, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: tint.border.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DuoIcon(card.icon, size: 24, color: const Color(0xFF1E293B)),
                          ),
                          const SizedBox(height: 12),
                          Text(t(card.titleKey, language), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.3)),
                          const SizedBox(height: 5),
                          Expanded(child: Text(t(card.descKey, language), style: TextStyle(fontSize: 12.5, color: colors.textSecondary, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: (200 + i * 50).ms, duration: 350.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PremiumStatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final ThemeColors colors;

  const _PremiumStatCard({required this.icon, required this.color, required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: colors.text.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DuoIcon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.text, letterSpacing: -0.5)),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted, fontWeight: FontWeight.w600, letterSpacing: 0.2), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
