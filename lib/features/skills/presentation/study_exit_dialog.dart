import 'package:flutter/material.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/theme/ilm_design.dart';
import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';
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
            // Ilmo asks the learner to stay, with the save state as a badge.
            ExcludeSemantics(
              child: Center(
                child: SizedBox(
                  width: 148,
                  height: 136,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Center(
                        child: AnimatedIlmo(pose: MascotPose.sad, size: 132),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: failed ? c?.warningLight : c?.primaryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c?.surface ?? theme.colorScheme.surface,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            failed
                                ? Icons.warning_amber_rounded
                                : saved
                                ? Icons.bookmark_added_outlined
                                : Icons.pause_rounded,
                            size: 18,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              namesRoute: true,
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: c?.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              str3(
                language,
                'Oldingi yutuqlaringiz saqlanadi.',
                'Предыдущие достижения сохранятся.',
                'Your earlier progress is safe.',
              ),
              textAlign: TextAlign.center,
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
