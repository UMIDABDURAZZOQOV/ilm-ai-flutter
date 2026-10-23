import 'package:flutter/material.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/theme/ilm_design.dart';
import 'skill_ui.dart';

enum StudyExitStatus { saved, saveFailed, unsaved }

/// A confirmation only: persisting the draft remains the caller's job.
class StudyExitDialog extends StatelessWidget {
  const StudyExitDialog({
    super.key,
    required this.language,
    required this.status,
  });

  final String language;
  final StudyExitStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<AppColors>()?.colors;
    final failed = status == StudyExitStatus.saveFailed;
    final saved = status == StudyExitStatus.saved;
    final accent = failed ? c?.warning : c?.primary;
    final title = str3(
      language,
      'Darsdan chiqasizmi?',
      'Выйти из урока?',
      'Leave this lesson?',
    );
    final message = switch (status) {
      StudyExitStatus.saved => str3(
        language,
        'Urinish shu qurilmada saqlandi. Dars muddati tugaguncha davom ettirishingiz mumkin.',
        'Попытка сохранена на этом устройстве. Можно продолжить до истечения срока урока.',
        'Your attempt is saved on this device. Resume before the lesson expires.',
      ),
      StudyExitStatus.saveFailed => str3(
        language,
        'Oxirgi o‘zgarishlarni saqlab bo‘lmadi. Chiqsangiz, ular yo‘qolishi mumkin.',
        'Не удалось сохранить последние изменения. При выходе они могут потеряться.',
        'Your latest changes could not be saved. Leaving may lose them.',
      ),
      StudyExitStatus.unsaved => str3(
        language,
        'Tugallanmagan urinish saqlanmaydi.',
        'Незавершённая попытка не сохранится.',
        'This unfinished attempt will not be saved.',
      ),
    };

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      constraints: const BoxConstraints(maxWidth: 400),
      backgroundColor: c?.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(IlmRadius.sheet),
        side: BorderSide(color: c?.border ?? theme.dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(IlmSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: failed ? c?.warningLight : c?.primaryLight,
                      borderRadius: BorderRadius.circular(IlmRadius.small),
                    ),
                    child: Icon(
                      failed
                          ? Icons.warning_amber_rounded
                          : saved
                          ? Icons.bookmark_added_outlined
                          : Icons.pause_rounded,
                      size: 23,
                      color: accent,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(title, style: theme.textTheme.titleLarge),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c?.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              str3(
                language,
                'Oldingi yutuqlaringiz saqlanadi.',
                'Предыдущие достижения сохранятся.',
                'Your earlier progress is safe.',
              ),
              style: theme.textTheme.bodySmall?.copyWith(color: c?.textMuted),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              child: Text(
                str3(language, 'Davom etish', 'Продолжить', 'Keep learning'),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context, true),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(IlmDesign.touchTarget),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                side: BorderSide(color: c?.border ?? theme.dividerColor),
              ),
              child: Text(
                saved
                    ? str3(
                        language,
                        'Saqlab chiqish',
                        'Сохранить и выйти',
                        'Save & leave',
                      )
                    : str3(language, 'Chiqish', 'Выйти', 'Leave'),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
