import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/romb_badge.dart';
import '../../../core/widgets/ilm_state_view.dart';
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
  'lessons': Color(0xFF2A1F6B),
  'perfect': Color(0xFFFFC800),
  'questions': Color(0xFF2DD4BF),
  'xp': Color(0xFFCE82FF),
};

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
        loading: () => const Center(child: CircularProgressIndicator()),
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
                    Icon(
                      Icons.emoji_events_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
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
                      style: Theme.of(context).textTheme.titleLarge,
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
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${str3(lang, 'Qo\'lga kiritilgan', 'Получено', 'Earned')}: $earned/${list.length}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
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
                        SizedBox(width: width, child: _badge(context, lang, a)),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _badge(BuildContext context, String lang, Achievement a) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final color = _groupColors[a.group] ?? const Color(0xFF2A1F6B);
    final icon = _groupIcons[a.group] ?? Icons.emoji_events_rounded;
    return Container(
      key: ValueKey('achievement_${a.id}'),
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.card,
        border: Border.all(
          color: a.earned ? color : colors.border,
          width: a.earned ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          a.earned
              ? RombBadge(
                  size: 44,
                  color: color.withValues(alpha: 0.16),
                  borderRadius: 10,
                  elevation: 0,
                  child: Icon(icon, color: colors.textSecondary, size: 22),
                )
              : Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
          const SizedBox(height: 6),
          Text('${a.target}', style: Theme.of(context).textTheme.titleLarge),
          Text(
            _groupLabel(lang, a.group),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
          ),
          if (!a.earned && a.progress > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${a.progress}/${a.target}',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  String _groupLabel(String lang, String group) {
    switch (group) {
      case 'streak':
        return str3(lang, 'kun seriya', 'дней подряд', 'day streak');
      case 'lessons':
        return str3(lang, 'dars', 'уроков', 'lessons');
      case 'perfect':
        return str3(lang, "3 yulduz", '3 звезды', '3 stars');
      case 'questions':
        return str3(lang, 'savol', 'вопросов', 'questions');
      case 'xp':
        return 'XP';
      default:
        return group;
    }
  }
}
