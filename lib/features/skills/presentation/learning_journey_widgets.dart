import 'dart:math' as math;
import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
import '../../../core/config/integrated_beta.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/mascot_image.dart';
import 'skill_ui.dart';
import '../application/lesson_entry.dart';
import '../data/skill_tree_models.dart';

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
    this.entry,
    this.courseNote,
    this.summary,
    this.statusLabel,
    this.compact = false,
  });
  final String language, title;
  final int todayXp, goalXp;
  final VoidCallback onGoal;
  final VoidCallback? onContinue;
  final bool checkpoint;
  final String? contentNote;
  final LessonEntry? entry;
  final String? courseNote;
  final GamificationSummary? summary;
  final String? statusLabel;
  final bool compact;

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
          if (!compact || onContinue != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry?.description(language) ??
                            statusLabel ??
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
                      Text(
                        title,
                        style: compact
                            ? Theme.of(context).textTheme.titleMedium
                            : Theme.of(context).textTheme.titleLarge,
                      ),
                      if (!compact && courseNote != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            courseNote!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      if (!compact && contentNote != null)
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
                AnimatedIlmo(
                  pose: entry?.state == LessonEntryState.resume
                      ? MascotPose.happy
                      : MascotPose.hello,
                  size:
                      compact || MediaQuery.textScalerOf(context).scale(16) > 24
                      ? 64
                      : 90,
                ),
              ],
            ),
          if (onContinue != null) ...[
            SizedBox(height: compact ? 4 : IlmSpace.md),
            if (compact)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: Text(
                    checkpoint
                        ? str3(
                            language,
                            'BO‘LIM SINOVI',
                            'ПРОВЕРКА РАЗДЕЛА',
                            'UNIT CHECKPOINT',
                          )
                        : entry?.action(language) ??
                              str3(
                                language,
                                'DAVOM ETISH',
                                'ПРОДОЛЖИТЬ',
                                'CONTINUE',
                              ),
                  ),
                ),
              )
            else
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
                      : entry?.action(language) ??
                            str3(
                              language,
                              'DAVOM ETISH',
                              'ПРОДОЛЖИТЬ',
                              'CONTINUE',
                            ),
                ),
              ),
          ],
          SizedBox(height: compact ? 2 : IlmSpace.sm),
          InkWell(
            onTap: onGoal,
            borderRadius: BorderRadius.circular(IlmRadius.small),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: EdgeInsets.symmetric(vertical: compact ? 8 : 16),
              child: Row(
                children: [
                  if (compact && onContinue == null) ...[
                    const AnimatedIlmo(pose: MascotPose.hello, size: 80),
                    const SizedBox(width: 12),
                  ],
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
            container: true,
            label: str3(language, 'Kunlik maqsad', 'Цель дня', 'Daily goal'),
            value: '$todayXp/$goalXp XP',
            child: ExcludeSemantics(
              child: LinearProgressIndicator(
                value: goalXp <= 0 ? 0 : (todayXp / goalXp).clamp(0.0, 1.0),
                minHeight: compact ? 4 : 6,
                color: Theme.of(context).brightness == Brightness.dark
                    ? c.accent
                    : c.success,
                backgroundColor: c.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (compact && (courseNote != null || contentNote != null)) ...[
            const SizedBox(height: 10),
            Text(
              [?courseNote, ?contentNote].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (summary != null &&
              (summary!.xpTotal > 0 || summary!.streakDays > 0)) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                Text(
                  str3(
                    language,
                    'Jami ${summary!.xpTotal} XP',
                    'Всего ${summary!.xpTotal} XP',
                    '${summary!.xpTotal} XP in total',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (summary!.streakDays > 0)
                  Text(
                    str3(
                      language,
                      'Seriya: ${summary!.streakDays} kun',
                      'Серия: ${summary!.streakDays} дн.',
                      'Streak: ${summary!.streakDays} ${summary!.streakDays == 1 ? 'day' : 'days'}',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class LearningUnitHeader extends StatelessWidget {
  const LearningUnitHeader({
    super.key,
    required this.title,
    required this.language,
    required this.completed,
    required this.total,
    required this.coverageComplete,
    this.expanded,
    this.current = false,
    this.onToggle,
  });
  final String title, language;
  final int completed, total;
  final bool coverageComplete;
  final bool? expanded;
  final bool current;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    // The current unit is a filled Duolingo-style banner with a 3D edge.
    final banner = current ? c.primary : c.surface;
    final ink = current ? foregroundOn(banner) : c.text;
    final inkSoft = current ? ink.withValues(alpha: .85) : c.textSecondary;
    return Semantics(
      container: true,
      button: onToggle == null ? null : true,
      expanded: expanded,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Material(
          color: banner,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(IlmRadius.card),
            side: current ? BorderSide.none : BorderSide(color: c.border),
          ),
          shadowColor: current ? duoShadowOf(banner) : null,
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      if (onToggle != null) ...[
                        const SizedBox(width: 8),
                        Icon(
                          expanded == true
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: inkSoft,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (current)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        str3(
                          language,
                          'Joriy bob',
                          'Текущий раздел',
                          'Current section',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: inkSoft,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .6,
                        ),
                      ),
                    ),
                  if (total > 0)
                    Text(
                      reviewedLearning
                          ? str3(
                              language,
                              'Bajarilgan darslar: $completed',
                              'Пройдено уроков: $completed',
                              'Lessons completed: $completed',
                            )
                          : str3(
                              language,
                              'Bajarilgan darslar: $completed/$total',
                              'Пройдено уроков: $completed/$total',
                              'Lessons completed: $completed/$total',
                            ),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: inkSoft),
                    ),
                  if (total > 0 && expanded != false) ...[
                    const SizedBox(height: 8),
                    ExcludeSemantics(
                      child: LinearProgressIndicator(
                        value: (completed / total).clamp(0, 1),
                        minHeight: 4,
                        color: current
                            ? ink
                            : Theme.of(context).brightness == Brightness.dark
                            ? c.accent
                            : c.success,
                        backgroundColor: current
                            ? ink.withValues(alpha: .25)
                            : c.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                  if (!coverageComplete)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        str3(
                          language,
                          'Bo‘limning qolgan darslari tayyorlanmoqda.',
                          'Остальные уроки раздела готовятся.',
                          'More lessons in this unit are in preparation.',
                        ),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: c.textMuted),
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

/// Duolingo-style path node: a large round 3D button that snakes left and
/// right down the path, with the lesson name underneath. The current lesson is
/// larger, carries a START bubble and an animated Ilmo beside it. Locked nodes
/// stay tappable: their existing sheet explains prerequisites.
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
    this.detail,
    this.pathIndex = 0,
    this.accent,
  });
  final String title, stateLabel, semanticLabel;
  final VoidCallback onTap;
  final bool locked, completed, current, checkpoint;
  final int stars;
  final String? detail;

  /// Position on the path; drives the left/right snake offset.
  final int pathIndex;

  /// Subject colour for unlocked nodes; falls back to the theme primary.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final icon = locked
        ? Icons.lock_rounded
        : completed
        ? Icons.check_rounded
        : checkpoint
        ? Icons.emoji_events_rounded
        : Icons.star_rounded;
    final face = locked
        ? c.border
        : completed
        ? c.success
        : (accent ?? c.primary);
    final node = current ? 84.0 : 72.0;
    // One semantics node at the tile root: label, state and tap target.
    return Semantics(
      container: true,
      button: true,
      selected: current,
      label:
          detail == null || detail!.isEmpty || semanticLabel.endsWith(detail!)
          ? semanticLabel
          : '$semanticLabel. $detail',
      onTap: onTap,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Snake pattern like a winding path: centre, right, centre, left.
          const pattern = [0.0, .55, .85, .55, 0.0, -.55, -.85, -.55];
          final reach = math.max(0.0, (constraints.maxWidth - 160) / 2);
          final dx =
              pattern[pathIndex % pattern.length] * math.min(reach, 90.0);
          final mascotLeft = dx > 0;
          final nodeButton = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (current)
                _StartBubble(label: stateLabel, color: face)
              else
                const SizedBox(height: 8),
              _PathNode(
                size: node,
                face: face,
                ring: current ? face : null,
                onTap: onTap,
                child: Icon(
                  icon,
                  size: node * .46,
                  color: locked ? c.textMuted : foregroundOn(face),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 220),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: locked ? c.textMuted : c.text,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              if (!locked && !current) ...[
                const SizedBox(height: 2),
                Text(
                  stateLabel,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: c.textSecondary),
                ),
              ],
              if (detail != null) ...[
                const SizedBox(height: 2),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    detail!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
              if (completed && stars > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < stars.clamp(0, 3); i++)
                        Icon(Icons.star_rounded, size: 18, color: c.warning),
                    ],
                  ),
                ),
            ],
          );
          const mascot = ExcludeSemantics(
            child: AnimatedIlmo(
              pose: MascotPose.hello,
              activity: IlmoActivity.greeting,
              size: 124,
            ),
          );
          final showMascot = current && constraints.maxWidth >= 300;
          // The whole row is a target, not only the round node.
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Transform.translate(
                offset: Offset(showMascot ? dx * .6 : dx, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (showMascot && mascotLeft) mascot,
                    Flexible(child: nodeButton),
                    if (showMascot && !mascotLeft) mascot,
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

/// Round 3D node with a pressed state, matching the Duo3DButton depth.
class _PathNode extends StatefulWidget {
  const _PathNode({
    required this.size,
    required this.face,
    required this.onTap,
    required this.child,
    this.ring,
  });
  final double size;
  final Color face;
  final Color? ring;
  final VoidCallback onTap;
  final Widget child;
  @override
  State<_PathNode> createState() => _PathNodeState();
}

class _PathNodeState extends State<_PathNode> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    const depth = 7.0;
    final ringPad = widget.ring == null ? 0.0 : 8.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: Container(
        padding: EdgeInsets.all(ringPad),
        decoration: widget.ring == null
            ? null
            : BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.ring!.withValues(alpha: .35),
                  width: 5,
                ),
              ),
        child: SizedBox(
          width: widget.size,
          height: widget.size + depth,
          child: Stack(
            children: [
              Positioned(
                top: depth,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: duoShadowOf(widget.face),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 70),
                top: _down ? depth : 0,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.face,
                  ),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "START"-style speech bubble above the current node.
class _StartBubble extends StatelessWidget {
  const _StartBubble({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 2),
        ),
        child: Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            letterSpacing: .6,
          ),
        ),
      ),
    );
  }
}
