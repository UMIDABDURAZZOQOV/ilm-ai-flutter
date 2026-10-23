import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../data/skill_tree_models.dart';
import 'skill_ui.dart';

/// Shared lesson/checkpoint structure, with no fixed content height.
class StudyStartSheet extends StatelessWidget {
  const StudyStartSheet({
    super.key,
    required this.language,
    required this.title,
    required this.icon,
    required this.description,
    required this.actionLabel,
    this.contextLabel,
    this.notice,
    this.details,
    this.onStart,
    this.locked = false,
  });
  final String language, title, description, actionLabel;
  final String? contextLabel, notice;
  final IconData icon;
  final Widget? details;
  final VoidCallback? onStart;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: IlmReadingWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (contextLabel != null) ...[
                Text(
                  contextLabel!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.primaryLight,
                        borderRadius: BorderRadius.circular(IlmRadius.small),
                      ),
                      child: Icon(icon, size: 23, color: c.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ),
                ],
              ),
              if (details != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: details!,
                ),
              const SizedBox(height: 16),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: c.textSecondary,
                ),
              ),
              if (notice != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: c.inputBackground,
                      border: Border.all(color: c.border),
                      borderRadius: BorderRadius.circular(IlmRadius.control),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(
                          child: Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : Icons.info_outline_rounded,
                            size: 20,
                            color: c.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            notice!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Duo3DButton(
                onPressed: locked ? null : onStart,
                child: Text(actionLabel, textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: Text(str3(language, 'Yopish', 'Закрыть', 'Close')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CheckpointPopoverContent extends StatelessWidget {
  const CheckpointPopoverContent({
    super.key,
    required this.unit,
    required this.language,
    this.onStart,
  });
  final SkillTreeUnit unit;
  final String language;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final locked = !{'unlocked', 'passed'}.contains(unit.examStatus);
    final passed = unit.examStatus == 'passed';
    return StudyStartSheet(
      language: language,
      title: unit.titleFor(language),
      contextLabel: str3(
        language,
        'Bo‘lim sinovi',
        'Проверка раздела',
        'Unit checkpoint',
      ),
      icon: passed ? Icons.verified_outlined : Icons.fact_check_outlined,
      description: passed
          ? str3(
              language,
              'Bu sinovdan o‘tgansiz. Bilimingizni yana tekshirishingiz mumkin.',
              'Вы уже прошли эту проверку. Можно проверить знания ещё раз.',
              'You have passed this checkpoint. You can practise it again.',
            )
          : str3(
              language,
              'Bo‘limda o‘rganganlaringizni tekshiring.',
              'Проверьте, что вы усвоили в этом разделе.',
              'Check what you have learned in this unit.',
            ),
      notice: locked
          ? !unit.coverageComplete
                ? str3(
                    language,
                    'Bobning qolgan darslari tayyorlanmoqda. Sinov hali ochilmaydi.',
                    'Остальные уроки главы готовятся. Проверка пока недоступна.',
                    'The remaining chapter lessons are in preparation. The checkpoint is not available yet.',
                  )
                : str3(
                    language,
                    'Bo‘limdagi barcha darslarni tugating.',
                    'Завершите все уроки в этом разделе.',
                    'Complete all lessons in this unit.',
                  )
          : null,
      locked: locked,
      actionLabel: locked
          ? str3(language, 'QULFLANGAN', 'ЗАБЛОКИРОВАНО', 'LOCKED')
          : passed
          ? str3(
              language,
              'SINOVNI TAKRORLASH',
              'ПОВТОРИТЬ ПРОВЕРКУ',
              'REVIEW CHECKPOINT',
            )
          : str3(
              language,
              'SINOVNI BOSHLASH',
              'НАЧАТЬ ПРОВЕРКУ',
              'START CHECKPOINT',
            ),
      onStart: onStart,
    );
  }
}
