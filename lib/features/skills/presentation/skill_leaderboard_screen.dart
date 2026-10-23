import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/ilm_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

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
  const SkillLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final async = ref.watch(_leaderboardProvider);
    final league = ref.watch(_leagueProvider);
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
            padding: const EdgeInsets.all(16),
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
                data: (l) => Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: c.card,
                    border: Border.all(color: c.border),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    children: [
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          for (final tier in l.allTiers)
                            Icon(
                              Icons.shield_rounded,
                              color: skillColor(tier.color).withValues(
                                alpha: l.weeklyXp >= tier.minXp ? 1 : .25,
                              ),
                              size: tier.id == l.league.id ? 48 : 28,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l.league.nameFor(lang),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${l.weeklyXp} XP',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (l.nextLeague != null) ...[
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: (l.nextLeague!.minXp - l.league.minXp) <= 0
                              ? 1
                              : ((l.weeklyXp - l.league.minXp) /
                                        (l.nextLeague!.minXp - l.league.minXp))
                                    .clamp(0.0, 1.0),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(8),
                          color: c.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          str3(
                            lang,
                            '${l.nextLeague!.nameFor(lang)} ligasiga ${l.xpToNext} XP qoldi',
                            'До лиги ${l.nextLeague!.nameFor(lang)}: ${l.xpToNext} XP',
                            '${l.xpToNext} XP to ${l.nextLeague!.nameFor(lang)}',
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (d.entries.isEmpty)
                Text(
                  str3(
                    lang,
                    'Bu haftada reyting ma’lumotlari hali yo‘q.',
                    'За эту неделю пока нет данных рейтинга.',
                    'No ranking data for this week yet.',
                  ),
                ),
              if (d.ownRank != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '${str3(lang, 'Sizning o\'rningiz', 'Ваше место', 'Your rank')}: #${d.ownRank}  ·  ${d.totalParticipants} ${str3(lang, 'ishtirokchi', 'участников', 'participants')}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              for (final e in d.entries) _row(context, lang, e),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, String lang, LeaderboardEntry e) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final medal = e.rank == 1
        ? '🥇'
        : e.rank == 2
        ? '🥈'
        : e.rank == 3
        ? '🥉'
        : null;
    final leagueColor = _leagueColors[e.league] ?? const Color(0xFFCD7F32);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: e.isMe ? c.primary.withValues(alpha: 0.08) : c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: e.isMe ? c.primary : c.border,
          width: e.isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 18))
                : Text(
                    '${e.rank}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: c.textSecondary,
                    ),
                  ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: leagueColor.withValues(alpha: 0.25),
            child: Text(
              e.name.isNotEmpty ? e.name[0].toUpperCase() : '?',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: c.text,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              e.name,
              style: TextStyle(
                fontWeight: e.isMe ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFFFC800)),
          Text(
            '${e.weeklyXp}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
