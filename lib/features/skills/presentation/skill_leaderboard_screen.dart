import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/animated_ilmo.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/ilm_state_view.dart';
import '../../../core/widgets/mascot_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';
import 'learning_invitation_card.dart';

final _leaderboardProvider = FutureProvider<LeaderboardResponse>((ref) async {
  ref.watch(studyRevisionProvider);
  ref.watch(currentUserIdProvider);
  return ref
      .read(skillExtrasRepositoryProvider)
      .getLeaderboard()
      .timeout(const Duration(seconds: 18));
});

final _leagueProvider = FutureProvider<LeagueResponse>((ref) async {
  ref.watch(studyRevisionProvider);
  final id = ref.watch(currentUserIdProvider);
  if (id == null) throw StateError('Not signed in');
  return ref
      .watch(skillExtrasRepositoryProvider)
      .getLeague(id)
      .timeout(const Duration(seconds: 18));
});

const _leagueColors = {
  'diamond': Color(0xFF7DD3FC),
  'gold': Color(0xFFFFC800),
  'silver': Color(0xFFC0C0C0),
  'bronze': Color(0xFFCD7F32),
};

class SkillLeaderboardScreen extends ConsumerWidget {
  const SkillLeaderboardScreen({super.key, this.onOpenLearning});
  final VoidCallback? onOpenLearning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final async = ref.watch(_leaderboardProvider);
    final league = ref.watch(_leagueProvider);
    final openLearning = onOpenLearning ?? () => context.go('/learn');
    return Scaffold(
      appBar: AppBar(
        title: Text(str3(lang, 'Liga', 'Лига', 'League')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: str3(lang, 'Yangilash', 'Обновить', 'Refresh'),
            onPressed: () {
              ref.invalidate(_leaderboardProvider);
              ref.invalidate(_leagueProvider);
            },
          ),
        ],
      ),
      body: async.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        loading: () => IlmLoadingView(language: lang),
        error: (_, _) => IlmStateView(
          title: str3(
            lang,
            'Liga yuklanmadi',
            'Лига не загружена',
            'League unavailable',
          ),
          message: str3(
            lang,
            'Ulanishni tekshirib, qayta urinib ko‘ring.',
            'Проверьте подключение и повторите попытку.',
            'Check your connection and try again.',
          ),
          retryLabel: str3(lang, 'Qayta urinish', 'Повторить', 'Try again'),
          onRetry: () {
            ref.invalidate(_leaderboardProvider);
            ref.invalidate(_leagueProvider);
          },
        ),
        data: (d) => IlmReadingWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              league.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => TextButton(
                  onPressed: () => ref.invalidate(_leagueProvider),
                  child: Text(
                    str3(
                      lang,
                      'Ligani qayta yuklash',
                      'Обновить лигу',
                      'Reload league',
                    ),
                  ),
                ),
                data: (l) => _LeagueHero(league: l, lang: lang),
              ),
              if (d.entries.isEmpty)
                LearningInvitationCard(
                  title: str3(
                    lang,
                    'Bu haftaning reytingi hali bo‘sh',
                    'Рейтинг этой недели пока пуст',
                    'This week’s ranking is still empty',
                  ),
                  message: str3(
                    lang,
                    'Darsni yakunlab XP yig‘ing. Haftalik natijalar shu yerda ko‘rinadi.',
                    'Проходите уроки и зарабатывайте XP. Здесь появятся результаты недели.',
                    'Complete lessons to earn XP. Weekly results will appear here.',
                  ),
                  actionLabel: str3(
                    lang,
                    'Dars yo‘liga o‘tish',
                    'Перейти к урокам',
                    'Go to learning path',
                  ),
                  onOpenLearning: openLearning,
                ),
              if (d.ownRank != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                  child: Row(
                    children: [
                      Icon(Icons.leaderboard_rounded, color: c.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${str3(lang, 'Sizning o‘rningiz', 'Ваше место', 'Your rank')}: #${d.ownRank}  ·  ${d.totalParticipants} ${str3(lang, 'ishtirokchi', 'участников', 'participants')}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (d.entries.isNotEmpty) ...[
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: c.border, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        for (final e in d.entries) _row(context, lang, e),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _KeepClimbing(lang: lang, onOpenLearning: openLearning),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String lang, LeaderboardEntry e) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final podium = switch (e.rank) {
      1 => const Color(0xFFFFB100),
      2 => const Color(0xFF9AA8B4),
      3 => const Color(0xFFD9822B),
      _ => null,
    };
    final leagueColor = _leagueColors[e.league] ?? const Color(0xFFCD7F32);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: e.isMe ? c.primary.withValues(alpha: .12) : null,
        borderRadius: BorderRadius.circular(16),
        border: e.isMe ? Border.all(color: c.primary, width: 2) : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: podium != null
                ? Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: podium,
                    ),
                    child: Text(
                      '${e.rank}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  )
                : Text(
                    '${e.rank}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: c.textSecondary,
                      fontSize: 16,
                    ),
                  ),
          ),
          const SizedBox(width: 6),
          CircleAvatar(
            radius: 20,
            backgroundColor: leagueColor.withValues(alpha: .28),
            child: Text(
              e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: c.text,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  e.name,
                  style: TextStyle(
                    fontWeight: e.isMe ? FontWeight.w900 : FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (e.isMe)
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: c.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        str3(lang, 'SIZ', 'ВЫ', 'YOU'),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Icon(Icons.bolt_rounded, size: 20, color: Color(0xFFFFB100)),
          Text(
            '${e.weeklyXp}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// League header: every tier in climbing order, the current one large.
class _LeagueHero extends StatelessWidget {
  const _LeagueHero({required this.league, required this.lang});
  final LeagueResponse league;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final l = league;
    final tone = skillColor(l.league.color);
    final next = l.nextLeague;
    final tiers = [...l.allTiers]..sort((a, b) => a.minXp.compareTo(b.minXp));
    final span = next == null ? 0 : next.minXp - l.league.minXp;
    final progress = span <= 0
        ? 1.0
        : ((l.weeklyXp - l.league.minXp) / span).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(tone.withValues(alpha: .26), c.card),
            c.card,
          ],
        ),
        border: Border.all(color: tone.withValues(alpha: .7), width: 2),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: tone.withValues(alpha: .45),
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final tier in tiers)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _TierBadge(
                    color: skillColor(tier.color),
                    current: tier.id == l.league.id,
                    reached: l.weeklyXp >= tier.minXp,
                    label: tier.nameFor(lang),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            str3(
              lang,
              '${l.league.nameFor(lang)} ligasi',
              'Лига: ${l.league.nameFor(lang)}',
              '${l.league.nameFor(lang)} League',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            str3(
              lang,
              'So‘nggi 7 kunda to‘plangan XP',
              'XP за последние 7 дней',
              'XP earned in the last 7 days',
            ),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFFFFB100),
                size: 26,
              ),
              Text(
                '${l.weeklyXp} XP',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (next != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 14,
                color: skillColor(next.color),
                backgroundColor: c.border,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              str3(
                lang,
                '${next.nameFor(lang)} ligasiga ${l.xpToNext} XP qoldi',
                'До лиги ${next.nameFor(lang)}: ${l.xpToNext} XP',
                '${l.xpToNext} XP to ${next.nameFor(lang)}',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }
}

class _TierBadge extends StatelessWidget {
  const _TierBadge({
    required this.color,
    required this.current,
    required this.reached,
    required this.label,
  });
  final Color color;
  final bool current;
  final bool reached;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final size = current ? 76.0 : 40.0;
    return Semantics(
      label: label,
      selected: current,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: reached
                ? color.withValues(alpha: current ? .22 : .16)
                : c.border.withValues(alpha: .6),
            boxShadow: current
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: .55),
                      blurRadius: 18,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.shield_rounded,
                size: size * .72,
                color: reached ? color : c.textMuted.withValues(alpha: .6),
              ),
              if (current)
                Icon(Icons.star_rounded, size: size * .3, color: Colors.white)
              else if (!reached)
                Icon(Icons.lock_rounded, size: size * .3, color: c.card),
            ],
          ),
        ),
      ),
    );
  }
}

/// Encouragement under the ranking, so the tab never ends in empty space.
class _KeepClimbing extends StatelessWidget {
  const _KeepClimbing({required this.lang, required this.onOpenLearning});
  final String lang;
  final VoidCallback onOpenLearning;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.primary.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.primary.withValues(alpha: .35), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: AnimatedIlmo(pose: MascotPose.happy, size: 96),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  str3(
                    lang,
                    'Har bir dars XP beradi. Ko‘proq o‘qing va yuqori ligaga chiqing!',
                    'Каждый урок даёт XP. Учитесь больше и поднимайтесь в лиге!',
                    'Every lesson earns XP. Keep learning to climb the leagues!',
                  ),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: Duo3DButton(
              onPressed: onOpenLearning,
              child: Text(str3(lang, 'XP YIG‘ISH', 'ЗАРАБОТАТЬ XP', 'EARN XP')),
            ),
          ),
        ],
      ),
    );
  }
}
