import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import 'skill_ui.dart';

/// Only acknowledged server results are passed here. No reward calculation.
class LessonCompletionView extends StatelessWidget {
  const LessonCompletionView({
    super.key,
    required this.language,
    required this.title,
    required this.lessonTitle,
    required this.xp,
    required this.correct,
    required this.total,
    required this.stars,
    required this.streakDays,
    required this.elapsed,
    required this.onReview,
    required this.onBack,
  });
  final String language, title, lessonTitle;
  final int xp, correct, total, stars, streakDays;
  final Duration elapsed;
  final VoidCallback onReview, onBack;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final theme = Theme.of(context);
    final accuracy = total == 0 ? 0 : (100 * correct / total).round();
    Widget stat(String value, String label, IconData icon) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.card,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(IlmRadius.control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(child: Icon(icon, size: 20, color: c.primary)),
          const SizedBox(height: 8),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: c.textSecondary),
          ),
        ],
      ),
    );
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: IlmReadingWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: MascotImage(
                    pose: accuracy >= 80 ? MascotPose.happy : MascotPose.hello,
                    size: 112,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  header: true,
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  lessonTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Semantics(
                  label: str3(
                    language,
                    '$stars/3 yulduz',
                    '$stars/3 звёзд',
                    '$stars/3 stars',
                  ),
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i <= stars
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 28,
                            color: i <= stars ? c.warning : c.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, box) {
                    final stacked =
                        MediaQuery.textScalerOf(context).scale(16) > 24 ||
                        box.maxWidth < 260;
                    final earned = stat(
                      '${xp >= 0 ? '+' : ''}$xp',
                      'XP',
                      Icons.bolt_rounded,
                    );
                    final score = stat(
                      '$correct/$total',
                      str3(
                        language,
                        'To‘g‘ri javoblar',
                        'Верные ответы',
                        'Correct answers',
                      ),
                      Icons.task_alt_rounded,
                    );
                    return stacked
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              earned,
                              const SizedBox(height: 12),
                              score,
                            ],
                          )
                        : IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(child: earned),
                                const SizedBox(width: 12),
                                Expanded(child: score),
                              ],
                            ),
                          );
                  },
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  runSpacing: 12,
                  children: [
                    Column(
                      children: [
                        Text('$accuracy%', style: theme.textTheme.titleLarge),
                        Text(
                          str3(
                            language,
                            'Birinchi urinish aniqligi',
                            'Точность первой попытки',
                            'First-attempt accuracy',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: theme.textTheme.titleLarge,
                        ),
                        Text(
                          str3(
                            language,
                            'Dars vaqti',
                            'Время урока',
                            'Lesson time',
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                if (streakDays > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      str3(
                        language,
                        'Seriyangiz: $streakDays kun',
                        'Ваша серия: $streakDays дн.',
                        'Your streak: $streakDays ${streakDays == 1 ? 'day' : 'days'}',
                      ),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                const SizedBox(height: 24),
                Duo3DButton(
                  onPressed: onBack,
                  child: Text(
                    str3(
                      language,
                      'Dars yo‘liga qaytish',
                      'К учебному пути',
                      'Back to learning path',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onReview,
                  icon: const Icon(Icons.fact_check_outlined),
                  label: Text(
                    str3(
                      language,
                      'Javoblarni ko‘rish',
                      'Посмотреть ответы',
                      'Review answers',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
