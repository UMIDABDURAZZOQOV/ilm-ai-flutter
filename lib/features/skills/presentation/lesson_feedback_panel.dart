import 'package:flutter/material.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import 'skill_ui.dart';

/// Full-width explanation, a small companion in the header, and a pinned action.
/// The entire explanation remains scrollable at large text sizes.
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
    this.source,
  });
  final String language, correctAnswer, explanation;
  final bool correct, reviewHint, saving;
  final VoidCallback onContinue;
  final String? saveError;
  final Widget? source;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final status = correct ? c.success : c.error;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .42,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: IlmDesign.readingWidth,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Flexible(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        primary: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (saveError != null) ...[
                              Semantics(
                                liveRegion: true,
                                child: Text(
                                  saveError!,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: c.error),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  correct
                                      ? Icons.check_circle_rounded
                                      : Icons.info_outline_rounded,
                                  size: 22,
                                  color: status,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Semantics(
                                    liveRegion: true,
                                    child: Text(
                                      t(
                                        correct
                                            ? 'skills.lesson.correct'
                                            : 'skills.lesson.incorrect',
                                        language,
                                      ),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(color: status),
                                    ),
                                  ),
                                ),
                                if (MediaQuery.textScalerOf(
                                      context,
                                    ).scale(16) <=
                                    24) ...[
                                  const SizedBox(width: 8),
                                  MascotImage(
                                    pose: correct
                                        ? MascotPose.happy
                                        : MascotPose.explaining,
                                    size: 36,
                                    animate: false,
                                  ),
                                ],
                              ],
                            ),
                            if (!correct) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 2,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    str3(
                                      language,
                                      'To‘g‘ri javob',
                                      'Правильный ответ',
                                      'Correct answer',
                                    ),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  Text(
                                    correctAnswer,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                ],
                              ),
                            ],
                            if (explanation.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                explanation,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                            if (source != null) ...[
                              const SizedBox(height: 8),
                              source!,
                            ],
                            if (reviewHint) ...[
                              const SizedBox(height: 8),
                              Text(
                                str3(
                                  language,
                                  'Bu savol oxirida yana chiqadi',
                                  'Этот вопрос появится снова в конце',
                                  'This question will appear again at the end',
                                ),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
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
                              value: MediaQuery.disableAnimationsOf(context)
                                  ? .75
                                  : null,
                              color: c.primary,
                            ),
                          )
                        : Text(t('skills.lesson.continue', language)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
