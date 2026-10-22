import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import '../../../core/widgets/romb_badge.dart';
import 'skill_ui.dart';

class LearningContinueCard extends StatelessWidget {
  const LearningContinueCard({
    super.key,
    required this.language,
    required this.title,
    required this.todayXp,
    required this.goalXp,
    required this.onGoal,
    this.onContinue,
    this.checkpoint = false,
    this.contentNote,
  });
  final String language, title;
  final int todayXp, goalXp;
  final VoidCallback onGoal;
  final VoidCallback? onContinue;
  final bool checkpoint;
  final String? contentNote;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Container(
      padding: const EdgeInsets.all(IlmSpace.md),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(IlmRadius.card),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      str3(
                        language,
                        'Bilim sari bir qadam',
                        'Ещё один шаг к знаниям',
                        'Your next learning step',
                      ),
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: c.primary),
                    ),
                    const SizedBox(height: IlmSpace.sm),
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (contentNote != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          contentNote!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: IlmSpace.sm),
              const MascotImage(pose: MascotPose.hello, size: 72),
            ],
          ),
          if (onContinue != null) ...[
            const SizedBox(height: IlmSpace.md),
            Duo3DButton(
              onPressed: onContinue,
              child: Text(
                checkpoint
                    ? str3(
                        language,
                        'BO‘LIM SINOVI',
                        'ПРОВЕРКА РАЗДЕЛА',
                        'UNIT CHECKPOINT',
                      )
                    : str3(language, 'DAVOM ETISH', 'ПРОДОЛЖИТЬ', 'CONTINUE'),
              ),
            ),
          ],
          const SizedBox(height: IlmSpace.sm),
          InkWell(
            onTap: onGoal,
            borderRadius: BorderRadius.circular(IlmRadius.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          str3(
                            language,
                            'KUNLIK MAQSAD',
                            'ЦЕЛЬ ДНЯ',
                            'DAILY GOAL',
                          ),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        Text(
                          '$todayXp/$goalXp XP',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: IlmSpace.sm),
                  Icon(Icons.tune_rounded, size: 20, color: c.primary),
                ],
              ),
            ),
          ),
          Semantics(
            label: str3(language, 'Kunlik maqsad', 'Цель дня', 'Daily goal'),
            value: '$todayXp/$goalXp XP',
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: goalXp <= 0 ? 0 : (todayXp / goalXp).clamp(0.0, 1.0),
                minHeight: 6,
                color: Theme.of(context).brightness == Brightness.dark
                    ? c.accent
                    : c.success,
                backgroundColor: c.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A whole-row target, readable names and a diamond milestone form ILM's path.
/// Locked rows remain inspectable: their existing sheet explains prerequisites.
class LearningJourneyTile extends StatelessWidget {
  const LearningJourneyTile({
    super.key,
    required this.title,
    required this.stateLabel,
    required this.semanticLabel,
    required this.onTap,
    required this.locked,
    required this.completed,
    required this.current,
    this.checkpoint = false,
    this.stars = 0,
  });
  final String title, stateLabel, semanticLabel;
  final VoidCallback onTap;
  final bool locked, completed, current, checkpoint;
  final int stars;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final icon = locked
        ? Icons.lock_outline_rounded
        : completed
        ? Icons.check_rounded
        : checkpoint
        ? Icons.emoji_events_outlined
        : Icons.star_rounded;
    return Semantics(
      button: true,
      selected: current,
      label: semanticLabel,
      onTap: onTap,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: current ? c.primaryLight : c.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IlmRadius.card),
            side: BorderSide(
              color: current ? c.primary : c.border,
              width: current ? 1.5 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RombBadge(
                    size: 52,
                    color: completed ? c.successLight : c.primaryLight,
                    borderColor: current ? c.primary : null,
                    borderWidth: 1.5,
                    child: Icon(
                      icon,
                      color: locked
                          ? c.textMuted
                          : completed
                          ? c.success
                          : c.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: locked ? c.textSecondary : c.text,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stateLabel,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: current ? c.primary : c.textSecondary,
                              ),
                        ),
                        if (completed && stars > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                for (var i = 0; i < stars.clamp(0, 3); i++)
                                  Icon(
                                    Icons.star_rounded,
                                    size: 18,
                                    color: c.warning,
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
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
