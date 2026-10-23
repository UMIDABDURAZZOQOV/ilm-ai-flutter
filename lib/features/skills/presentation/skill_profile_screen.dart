import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/ilm_state_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';
import 'streak_calendar_widget.dart';

/// Kept across tab switches so Profile does not spinner-reload on every visit.
final skillProfileProvider = FutureProvider<SkillProfile?>((ref) async {
  ref.watch(studyRevisionProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref
      .read(skillExtrasRepositoryProvider)
      .getProfile(userId)
      .timeout(const Duration(seconds: 18));
});

class SkillProfileScreen extends ConsumerWidget {
  const SkillProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final sessionName = ref.watch(authControllerProvider).valueOrNull?.name;
    final async = ref.watch(skillProfileProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(str3(lang, 'Mening profilim', 'Мой профиль', 'My profile')),
        actions: [
          IconButton(
            tooltip: str3(lang, 'Sozlamalar', 'Настройки', 'Settings'),
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
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
            'Profil yuklanmadi',
            'Профиль не загружен',
            'Profile unavailable',
          ),
          message: str3(
            lang,
            'Ulanishni tekshirib, qayta urinib ko‘ring.',
            'Проверьте подключение и повторите попытку.',
            'Check your connection and try again.',
          ),
          retryLabel: str3(lang, 'Qayta urinish', 'Повторить', 'Try again'),
          onRetry: () => ref.invalidate(skillProfileProvider),
        ),
        data: (p) => p == null
            ? const SizedBox()
            : IlmReadingWidth(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    () {
                      final displayName =
                          (sessionName != null && sessionName.isNotEmpty)
                          ? sessionName
                          : p.name;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: c.primary.withValues(alpha: 0.12),
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: c.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: c.primary.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${p.league.nameFor(lang)} ${str3(lang, 'ligasi', 'лига', 'league')}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: c.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }(),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        _tile(
                          context,
                          Icons.bolt_rounded,
                          c.warning,
                          '${p.xpTotal}',
                          'XP',
                        ),
                        const SizedBox(width: 10),
                        _tile(
                          context,
                          Icons.local_fire_department_rounded,
                          c.warning,
                          '${p.streakDays}',
                          str3(lang, 'kun', 'дней', 'streak'),
                        ),
                        const SizedBox(width: 10),
                        _tile(
                          context,
                          Icons.menu_book_rounded,
                          c.primary,
                          '${p.lessonsCompleted}',
                          str3(lang, 'dars', 'уроков', 'lessons'),
                        ),
                      ],
                    ),
                    if (p.strongest != null || p.weakest != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (p.strongest != null)
                            Expanded(
                              child: _sw(
                                context,
                                str3(
                                  lang,
                                  'Eng kuchli',
                                  'Сильнейший',
                                  'Strongest',
                                ),
                                p.strongest!.nameFor(lang),
                                '${p.strongest!.pct}%',
                                c.success,
                              ),
                            ),
                          if (p.strongest != null &&
                              p.weakest != null &&
                              p.weakest!.slug != p.strongest!.slug)
                            const SizedBox(width: 10),
                          if (p.weakest != null &&
                              p.weakest!.slug != p.strongest?.slug)
                            Expanded(
                              child: _sw(
                                context,
                                str3(
                                  lang,
                                  'Mashq uchun',
                                  'Для практики',
                                  'To practise',
                                ),
                                p.weakest!.nameFor(lang),
                                '${p.weakest!.pct}%',
                                c.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    StreakCalendarWidget(
                      activity: p.activity,
                      streakDays: p.streakDays,
                      language: lang,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      str3(
                        lang,
                        'Faollik (12 hafta)',
                        'Активность (12 недель)',
                        'Activity (12 weeks)',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    _Heatmap(activity: p.activity, weeks: 12, language: lang),
                    const SizedBox(height: 8),
                    Text(
                      str3(
                        lang,
                        'Har katak — bir kun. Rang to‘qligi yakunlangan dars urinishlari sonini bildiradi.',
                        'Одна клетка — один день. Насыщенность показывает число завершённых попыток урока.',
                        'Each cell is a day. Darker colours show more completed lesson attempts.',
                      ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      str3(
                        lang,
                        'Fanlar bo\'yicha',
                        'По предметам',
                        'By subject',
                      ),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    for (final s in p.subjects) _subjectBar(context, lang, s),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    Color color,
    String value,
    String label,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _sw(
    BuildContext context,
    String label,
    String subject,
    String pct,
    Color color,
  ) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          subject,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
        ),
        Text(
          pct,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _subjectBar(BuildContext context, String lang, SubjectProgress s) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    s.nameFor(lang),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${s.completed}/${s.total} · ⭐${s.stars}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: s.total == 0 ? 0 : s.completed / s.total,
                minHeight: 9,
                color: skillColor(s.color),
                backgroundColor: Theme.of(context).dividerColor,
              ),
            ),
          ],
        ),
      );
}

class _Heatmap extends StatelessWidget {
  final Map<String, int> activity;
  final int weeks;
  final String language;
  const _Heatmap({
    required this.activity,
    required this.weeks,
    required this.language,
  });

  @override
  Widget build(BuildContext context) {
    final days = weeks * 7;
    final today = DateTime.now().toUtc();
    final cols = <List<(String, int)>>[];
    var current = <(String, int)>[];
    for (var i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final key =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      current.add((key, activity[key] ?? 0));
      if (current.length == 7) {
        cols.add(current);
        current = <(String, int)>[];
      }
    }
    if (current.isNotEmpty) cols.add(current);

    Color shade(int c) {
      if (c == 0) return Theme.of(context).dividerColor;
      if (c < 2) return const Color(0xFF2DD4BF).withValues(alpha: 0.35);
      if (c < 4) return const Color(0xFF2DD4BF);
      return const Color(0xFF0F766E);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final col in cols)
            Padding(
              padding: const EdgeInsets.only(right: 3),
              child: Column(
                children: [
                  for (final day in col)
                    Semantics(
                      label:
                          '${day.$1}. ${str3(language, 'Yakunlangan urinishlar', 'Завершено попыток', 'Completed attempts')}: ${day.$2}',
                      excludeSemantics: true,
                      child: Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.only(bottom: 3),
                        decoration: BoxDecoration(
                          color: shade(day.$2),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
