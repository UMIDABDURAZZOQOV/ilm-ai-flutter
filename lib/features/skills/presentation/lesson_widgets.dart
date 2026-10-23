import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/duo_chrome.dart';
import 'skill_ui.dart';
export 'lesson_feedback_panel.dart';

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
