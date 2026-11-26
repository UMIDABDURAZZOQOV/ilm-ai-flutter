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
import 'learning_invitation_card.dart';

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
  const SkillProfileScreen({super.key, this.onOpenLearning});
  final VoidCallback? onOpenLearning;

  bool _hasProgress(SkillProfile p) =>
      p.xpTotal > 0 ||
      p.streakDays > 0 ||
      p.lessonsCompleted > 0 ||
      p.activity.values.any((value) => value > 0) ||
      [
        ...p.subjects,
        if (p.strongest != null) p.strongest!,
        if (p.weakest != null) p.weakest!,
      ].any((s) => s.completed > 0 || s.stars > 0 || s.pct > 0);

  /// 1 урок, 2 урока, 5 уроков, 11 уроков, 21 урок.
  static String _ruLessons(int n) {
    final tens = n % 100, ones = n % 10;
    if (tens >= 11 && tens <= 14) return 'уроков';
    if (ones == 1) return 'урок';
    if (ones >= 2 && ones <= 4) return 'урока';
    return 'уроков';
  }

  /// Any started subject shows a visible sliver rather than an empty bar.
  double _barValue(SubjectProgress subject) => subject.completed > 0
      ? (subject.pct / 100).clamp(0.03, 1.0).toDouble()
      : 0;

  /// "12% completed": a bare percentage left learners guessing what it meant.
  String _progressLabel(SubjectProgress subject, String lang) {
    final value =
        subject.pct == 0 &&
            subject.completed > 0 &&
            subject.total > subject.completed * 100
        ? '<1%'
        : '${subject.pct}%';
    return str3(
      lang,
      '$value o‘zlashtirildi',
      '$value пройдено',
      '$value completed',
    );
  }

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
                    Builder(
                      builder: (context) {
                        final statistics = Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                                  const Color(0xFFFF8A00),
                                  '${p.streakDays}',
                                  str3(lang, 'kun', 'дней', 'streak'),
                                ),
                                const SizedBox(width: 10),
                                _tile(
                                  context,
                                  Icons.menu_book_rounded,
                                  c.primary,
                                  '${p.lessonsCompleted}',
                                  str3(
                                    lang,
                                    'dars',
                                    _ruLessons(p.lessonsCompleted),
                                    p.lessonsCompleted == 1
                                        ? 'lesson'
                                        : 'lessons',
                                  ),
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
                                        _progressLabel(p.strongest!, lang),
                                        _barValue(p.strongest!),
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
                                        _progressLabel(p.weakest!, lang),
                                        _barValue(p.weakest!),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _Heatmap(
                              activity: p.activity,
                              weeks: 12,
                              language: lang,
                            ),
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
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final s in p.subjects)
                              _subjectBar(context, lang, s),
                          ],
                        );
                        if (_hasProgress(p)) return statistics;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LearningInvitationCard(
                              title: str3(
                                lang,
                                'Birinchi darsdan boshlaymiz',
                                'Начнём с первого урока',
                                'Start with your first lesson',
                              ),
                              message: str3(
                                lang,
                                'Darsni yakunlang — XP, faollik va yutuqlaringiz shu yerda ko‘rinadi.',
                                'Завершите урок — здесь появятся ваши XP, активность и достижения.',
                                'Complete a lesson to see your XP, activity and achievements here.',
                              ),
                              actionLabel: str3(
                                lang,
                                'Dars yo‘liga o‘tish',
                                'Перейти к урокам',
                                'Go to learning path',
                              ),
                              onOpenLearning:
                                  onOpenLearning ?? () => context.go('/learn'),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              clipBehavior: Clip.antiAlias,
                              child: ExpansionTile(
                                shape: const Border(),
                                collapsedShape: const Border(),
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                childrenPadding: const EdgeInsets.all(16),
                                leading: const Icon(Icons.insights_outlined),
                                title: Text(
                                  str3(
                                    lang,
                                    'Statistika va faollik',
                                    'Статистика и активность',
                                    'Statistics and activity',
                                  ),
                                ),
                                subtitle: Text(
                                  str3(
                                    lang,
                                    'XP, kalendar va fanlar bo‘yicha progress',
                                    'XP, календарь и прогресс по предметам',
                                    'XP, calendar and subject progress',
                                  ),
                                ),
                                children: [statistics],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
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
      // Each stat carries its own colour, like Duolingo's profile tiles.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.alphaBlend(
          color.withValues(alpha: .12),
          Theme.of(context).colorScheme.surface,
        ),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: color,
            ),
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
    double progress,
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
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: color,
            backgroundColor: color.withValues(alpha: 0.18),
          ),
        ),
        const SizedBox(height: 4),
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
