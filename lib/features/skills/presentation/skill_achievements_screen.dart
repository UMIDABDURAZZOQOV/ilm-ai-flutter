import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/animated_ilmo.dart';
import '../../../core/widgets/ilm_state_view.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_extras_models.dart';
import '../data/skill_extras_repository.dart';
import 'skill_ui.dart';

final _achievementsProvider = FutureProvider.autoDispose<List<Achievement>>((
  ref,
) async {
  ref.watch(studyRevisionProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref
      .read(skillExtrasRepositoryProvider)
      .getAchievements(userId)
      .timeout(const Duration(seconds: 18));
});

const _groupIcons = {
  'streak': Icons.local_fire_department_rounded,
  'lessons': Icons.menu_book_rounded,
  'perfect': Icons.star_rounded,
  'questions': Icons.help_outline_rounded,
  'xp': Icons.bolt_rounded,
};

const _groupColors = {
  'streak': Color(0xFFFF9600),
  'lessons': Color(0xFF6754D4),
  'perfect': Color(0xFFFFB800),
  'questions': Color(0xFF14B8A6),
  'xp': Color(0xFFCE82FF),
};

/// Russian noun form for a count: 1 урок, 2 урока, 5 уроков.
String _ru(int n, String one, String few, String many) {
  final tens = n % 100, ones = n % 10;
  if (tens >= 11 && tens <= 14) return many;
  if (ones == 1) return one;
  if (ones >= 2 && ones <= 4) return few;
  return many;
}

class SkillAchievementsScreen extends ConsumerWidget {
  const SkillAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final async = ref.watch(_achievementsProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(str3(lang, 'Yutuqlar', 'Достижения', 'Achievements')),
      ),
      body: async.when(
        loading: () => IlmLoadingView(language: lang),
        error: (_, _) => IlmStateView(
          title: str3(
            lang,
            'Yutuqlar yuklanmadi',
            'Не удалось загрузить достижения',
            'Achievements unavailable',
          ),
          message: str3(
            lang,
            'Ulanishni tekshirib, qayta urinib ko‘ring.',
            'Проверьте подключение и повторите попытку.',
            'Check your connection and try again.',
          ),
          retryLabel: str3(lang, 'Qayta urinish', 'Повторить', 'Retry'),
          onRetry: () => ref.invalidate(_achievementsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const ExcludeSemantics(
                      child: AnimatedIlmo(pose: MascotPose.hello, size: 140),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      str3(
                        lang,
                        'Hozircha yutuqlar yo‘q',
                        'Достижений пока нет',
                        'No achievements yet',
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      str3(
                        lang,
                        'O‘qishni davom ettiring. Yutuqlaringiz shu yerda ko‘rinadi.',
                        'Продолжайте учиться. Ваши достижения появятся здесь.',
                        'Keep learning. Your achievements will appear here.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          final earned = list.where((a) => a.earned).length;
          // Not lazy: the badge grid must exist even when a large-text hero
          // pushes it below the first screen.
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Summary(lang: lang, earned: earned, total: list.length),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final scale =
                        MediaQuery.textScalerOf(context).scale(14) / 14;
                    final columns = (constraints.maxWidth / (140 * scale))
                        .floor()
                        .clamp(1, 4);
                    final width =
                        (constraints.maxWidth - 12 * (columns - 1)) / columns;
                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        for (final a in list)
                          SizedBox(
                            width: width,
                            child: _badge(context, lang, a),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _badge(BuildContext context, String lang, Achievement a) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final color = _groupColors[a.group] ?? const Color(0xFF6754D4);
    final icon = _groupIcons[a.group] ?? Icons.emoji_events_rounded;
    final value = a.target <= 0
        ? 0.0
        : (a.progress / a.target).clamp(0.0, 1.0).toDouble();
    return Container(
      key: ValueKey('achievement_${a.id}'),
      constraints: const BoxConstraints(minHeight: 172),
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: a.earned
            ? Color.alphaBlend(color.withValues(alpha: .12), colors.card)
            : colors.card,
        border: Border.all(color: a.earned ? color : colors.border, width: 2),
        boxShadow: a.earned
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .5),
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: SizedBox(
              width: 64,
              height: 60,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: a.earned
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                color,
                                Color.lerp(color, Colors.black, .25)!,
                              ],
                            )
                          : null,
                      color: a.earned ? null : colors.border,
                    ),
                    child: Icon(
                      icon,
                      size: 30,
                      color: a.earned
                          ? Colors.white
                          : color.withValues(alpha: .55),
                    ),
                  ),
                  if (a.earned)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.success,
                          border: Border.all(color: colors.card, width: 2),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${a.target}',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            _groupLabel(lang, a.group, a.target),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          if (a.earned)
            Text(
              str3(lang, 'Qo‘lga kiritildi', 'Получено', 'Earned'),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color.lerp(color, colors.text, .35),
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            )
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 8,
                color: color,
                backgroundColor: colors.border,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${a.progress.clamp(0, a.target)}/${a.target}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _groupLabel(String lang, String group, int n) {
    switch (group) {
      case 'streak':
        return str3(
          lang,
          'kunlik seriya',
          '${_ru(n, 'день', 'дня', 'дней')} подряд',
          'day streak',
        );
      case 'lessons':
        return str3(
          lang,
          'dars',
          _ru(n, 'урок', 'урока', 'уроков'),
          n == 1 ? 'lesson' : 'lessons',
        );
      case 'perfect':
        return str3(
          lang,
          '3 yulduzli dars',
          '${_ru(n, 'урок', 'урока', 'уроков')} на 3 звезды',
          n == 1 ? '3-star lesson' : '3-star lessons',
        );
      case 'questions':
        return str3(
          lang,
          'savol',
          _ru(n, 'вопрос', 'вопроса', 'вопросов'),
          n == 1 ? 'question' : 'questions',
        );
      case 'xp':
        return 'XP';
      default:
        return group;
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.lang,
    required this.earned,
    required this.total,
  });
  final String lang;
  final int earned, total;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6754D4), Color(0xFF8B7CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0xFF4A3AA8), offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${str3(lang, 'Qo‘lga kiritilgan', 'Получено', 'Earned')}: $earned/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  str3(
                    lang,
                    'Har bir dars yangi yutuqqa yaqinlashtiradi.',
                    'Каждый урок приближает новую награду.',
                    'Every lesson brings the next badge closer.',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : earned / total,
                    minHeight: 12,
                    color: colors.warning,
                    backgroundColor: Colors.white.withValues(alpha: .3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const ExcludeSemantics(
            child: AnimatedIlmo(pose: MascotPose.happy, size: 96),
          ),
        ],
      ),
    );
  }
}
