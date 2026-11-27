import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../../core/widgets/animated_ilmo.dart';
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
    this.onReview,
    required this.onBack,
    this.reviewLabel,
    this.passed,
    this.backIsSecondary = false,
  });
  final String language, title, lessonTitle;
  final String? reviewLabel;
  final bool? passed;

  /// True when the host screen pins all actions (next, back, practise again)
  /// below this view; the view then shows only the result.
  final bool backIsSecondary;
  final int xp, correct, total, stars, streakDays;
  final Duration elapsed;
  final VoidCallback onBack;

  /// Null when the host screen pins this action as its primary button.
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final theme = Theme.of(context);
    final accuracy = total == 0 ? 0 : (100 * correct / total).round();
    final celebrate = passed ?? (accuracy >= 80);
    // Duolingo-style result tiles: each metric has its own colour.
    Widget stat(String value, String label, IconData icon, Color tone) =>
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color.alphaBlend(tone.withValues(alpha: .12), c.card),
            border: Border.all(color: tone, width: 2),
            borderRadius: BorderRadius.circular(IlmRadius.control),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(icon, size: 24, color: tone)),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: c.textSecondary,
                ),
              ),
            ],
          ),
        );
    return SafeArea(
      child: LayoutBuilder(
        // Under pinned actions a 360x800 phone leaves ~500 dp: a smaller Ilmo
        // keeps the accuracy and time rows in view without scrolling.
        builder: (context, box) {
          final short = box.maxHeight < 620;
          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                short ? 8 : 24,
                24,
                short ? 8 : 24,
              ),
              child: IlmReadingWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: AnimatedIlmo(
                        pose: celebrate ? MascotPose.happy : MascotPose.hello,
                        activity: celebrate
                            ? IlmoActivity.celebrating
                            : IlmoActivity.encouraging,
                        size: short ? 104 : 157,
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
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
                          c.warning,
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
                          c.success,
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
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
                            Text(
                              '$accuracy%',
                              style: theme.textTheme.titleLarge,
                            ),
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
                              elapsed.inHours >= 1
                                  ? str3(
                                      language,
                                      '${elapsed.inHours} soat ${elapsed.inMinutes % 60} daq',
                                      '${elapsed.inHours} ч ${elapsed.inMinutes % 60} мин',
                                      '${elapsed.inHours} h ${elapsed.inMinutes % 60} min',
                                    )
                                  : '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                              style: theme.textTheme.titleLarge,
                            ),
                            Text(
                              str3(
                                language,
                                'Jami vaqt (tanaffus bilan)',
                                'Общее время (с перерывами)',
                                'Total time (including breaks)',
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
                    // A host that pins every action (backIsSecondary) draws none
                    // here, so no half-visible button sits under its fade.
                    if (!backIsSecondary) ...[
                      const SizedBox(height: 24),
                      // Secondary: the lesson screen pins the primary next action.
                      Duo3DButton(
                        key: const ValueKey('completion_back_to_path'),
                        color: backIsSecondary ? c.card : null,
                        textColor: backIsSecondary ? c.primary : null,
                        borderColor: backIsSecondary ? c.border : null,
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
                      if (onReview != null) const SizedBox(height: 8),
                      if (onReview != null)
                        OutlinedButton.icon(
                          onPressed: onReview,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: Text(
                            reviewLabel ??
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
