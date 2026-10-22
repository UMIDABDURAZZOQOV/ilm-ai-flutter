import 'package:flutter/material.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import 'skill_ui.dart';

class LessonStepHeader extends StatelessWidget {
  const LessonStepHeader({
    super.key,
    required this.label,
    required this.progress,
    required this.onClose,
    required this.language,
    this.uzbekContent = false,
  });
  final String label, language;
  final double progress;
  final VoidCallback onClose;
  final bool uzbekContent;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
      child: Row(
        children: [
          IconButton(
            tooltip: str3(
              language,
              'Darsni yopish',
              'Закрыть урок',
              'Close lesson',
            ),
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    if (uzbekContent)
                      Semantics(
                        label: str3(
                          language,
                          'Dars mazmuni: o‘zbekcha',
                          'Содержание урока: узбекский',
                          'Lesson content: Uzbek',
                        ),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            'UZ',
                            style: Theme.of(
                              context,
                            ).textTheme.labelMedium?.copyWith(color: c.primary),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                DuoProgressBar(value: progress),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Explanation scrolls independently; the next action stays outside that scroll.
/// No grades/rewards are calculated here.
class LessonFeedbackPanel extends StatelessWidget {
  const LessonFeedbackPanel({
    super.key,
    required this.language,
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.onContinue,
    this.reviewHint = false,
    this.saving = false,
    this.saveError,
  });
  final String language, correctAnswer, explanation;
  final bool correct, reviewHint, saving;
  final VoidCallback onContinue;
  final String? saveError;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final status = correct ? c.success : c.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(top: BorderSide(color: c.border)),
      ),
      child: IlmReadingWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * .32,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (saveError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Semantics(
                          liveRegion: true,
                          child: Text(
                            saveError!,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(color: c.error),
                          ),
                        ),
                      ),
                    Semantics(
                      liveRegion: true,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            correct
                                ? Icons.check_circle_rounded
                                : Icons.info_outline_rounded,
                            size: 24,
                            color: status,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t(
                                correct
                                    ? 'skills.lesson.correct'
                                    : 'skills.lesson.incorrect',
                                language,
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(color: status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (MediaQuery.textScalerOf(context).scale(15) <= 22.5)
                          MascotImage(
                            pose: correct
                                ? MascotPose.happy
                                : MascotPose.explaining,
                            size: 72,
                          ),
                        if (MediaQuery.textScalerOf(context).scale(15) <= 22.5)
                          const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (!correct) ...[
                                Text(
                                  str3(
                                    language,
                                    'To‘g‘ri javob',
                                    'Правильный ответ',
                                    'Correct answer',
                                  ),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.labelMedium,
                                ),
                                Text(
                                  correctAnswer,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (explanation.isNotEmpty)
                                Text(
                                  explanation,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (reviewHint)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    str3(
                                      language,
                                      'Bu savol oxirida yana chiqadi',
                                      'Этот вопрос появится снова в конце',
                                      'This question will appear again at the end',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Duo3DButton(
              onPressed: saving ? null : onContinue,
              child: saving
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.primary,
                      ),
                    )
                  : Text(t('skills.lesson.continue', language)),
            ),
          ],
        ),
      ),
    );
  }
}
