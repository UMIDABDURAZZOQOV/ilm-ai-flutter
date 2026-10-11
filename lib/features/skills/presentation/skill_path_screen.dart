import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'hearts_xp_widgets.dart';
import 'mascot.dart';
import 'skill_ui.dart';
import 'skill_practice_screen.dart';
import 'daily_goal_bottom_sheet.dart';

const _nodeSpacing = 104.0;
const _amplitude = 64.0;

enum LessonLockReason {
  previousLessonIncomplete,
  checkpointRequired;

  String message(String language) {
    switch (this) {
      case LessonLockReason.previousLessonIncomplete:
        return str3(
          language,
          'Oldingi dars tugallanmagan.',
          'Предыдущий урок не завершен.',
          'Complete the previous lesson first.',
        );
      case LessonLockReason.checkpointRequired:
        return str3(
          language,
          'Bo‘lim sinovidan o‘tish kerak.',
          'Требуется пройти проверку раздела.',
          'Unit checkpoint is required.',
        );
    }
  }
}

LessonLockReason? resolveLessonLockReason({
  required SkillTreeResponse tree,
  required SkillTreeLesson lesson,
}) {
  if (lesson.status != LessonStatus.locked) return null;
  final unitIndex = tree.units.indexWhere(
    (u) => u.lessons.any((l) => l.id == lesson.id),
  );
  if (unitIndex == -1) return null;
  final hasUnpassedCheckpointBefore = tree.units
      .take(unitIndex)
      .any((u) => u.examStatus != 'passed' && u.examStatus != 'none');
  return hasUnpassedCheckpointBefore
      ? LessonLockReason.checkpointRequired
      : LessonLockReason.previousLessonIncomplete;
}

class _PathItem {
  final SkillTreeLesson? lesson;
  final SkillTreeUnit? unit;
  final String unitTitle;
  final bool unitStart;
  final bool isCheckpoint;
  final LessonLockReason? lockReason;

  _PathItem.lesson({
    required SkillTreeLesson this.lesson,
    required this.unitTitle,
    required this.unitStart,
    this.lockReason,
  })  : isCheckpoint = false,
        unit = null;

  _PathItem.checkpoint({
    required SkillTreeUnit this.unit,
    required this.unitTitle,
  })  : isCheckpoint = true,
        lesson = null,
        unitStart = false,
        lockReason = null;
}

final _treeProvider = FutureProvider.autoDispose
    .family<SkillTreeResponse, String>((ref, subjectSlug) async {
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) throw Exception('not authenticated');
      return ref
          .read(skillTreeRepositoryProvider)
          .getTree(userId: userId, subjectSlug: subjectSlug);
    });

class SkillPathScreen extends ConsumerWidget {
  final SkillSubject subject;
  final VoidCallback? onChangeSubject;
  const SkillPathScreen({
    super.key,
    required this.subject,
    this.onChangeSubject,
  });

  Future<void> _sections(
    BuildContext context,
    WidgetRef ref,
    SkillTreeResponse tree,
    String lang,
  ) async {
    final unit = await showModalBottomSheet<SkillTreeUnit>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .7,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                str3(lang, 'Bo‘limlar', 'Разделы', 'Sections'),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await context.push(
                    '/skills/practice',
                    extra: {
                      'mode': PracticeMode.placement,
                      'subject': subject.slug,
                    },
                  );
                },
                icon: const Icon(Icons.insights_rounded),
                label: Text(
                  str3(
                    lang,
                    'Darajamni aniqlash',
                    'Узнать свой уровень',
                    'Find my level',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final u in tree.units)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          u.titleFor(lang),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${u.lessons.where((l) => l.status == LessonStatus.completed).length}/${u.lessons.length} ${str3(lang, 'dars', 'уроков', 'lessons')}',
                        ),
                        const SizedBox(height: 12),
                        for (final lesson in u.lessons)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('• ${lesson.titleFor(lang)}'),
                          ),
                        if (u.examStatus != 'none')
                          FilledButton.icon(
                            onPressed:
                                {'unlocked', 'passed'}.contains(u.examStatus)
                                ? () => Navigator.pop(ctx, u)
                                : null,
                            icon: Icon(
                              u.examStatus == 'passed'
                                  ? Icons.verified_rounded
                                  : Icons.emoji_events_rounded,
                            ),
                            label: Text(
                              u.examStatus == 'passed'
                                  ? str3(
                                      lang,
                                      'Sinovni takrorlash',
                                      'Повторить проверку',
                                      'Review checkpoint',
                                    )
                                  : str3(
                                      lang,
                                      'Bo‘lim sinovi',
                                      'Проверка раздела',
                                      'Unit checkpoint',
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (unit == null || !context.mounted) return;
    await context.push(
      '/skills/practice',
      extra: {'mode': PracticeMode.checkpoint, 'unit_id': unit.id},
    );
    if (context.mounted) ref.invalidate(_treeProvider(subject.slug));
  }

  Future<void> _showLessonPopover({
    required BuildContext context,
    required WidgetRef ref,
    required SkillTreeLesson lesson,
    required String language,
    required Color color,
    String? unitTitle,
    LessonLockReason? lockReason,
  }) async {
    final start = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => LessonPopoverContent(
        lesson: lesson,
        unitTitle: unitTitle,
        language: language,
        color: color,
        lockReason: lockReason,
        onStart: () => Navigator.pop(ctx, true),
      ),
    );
    if (start != true || !context.mounted) return;
    await context.push('/skills/lesson', extra: lesson);
    if (context.mounted) ref.invalidate(_treeProvider(subject.slug));
  }

  Future<void> _showCheckpointPopover({
    required BuildContext context,
    required WidgetRef ref,
    required SkillTreeUnit unit,
    required String language,
    required Color color,
  }) async {
    final locked = unit.examStatus == 'locked';
    final passed = unit.examStatus == 'passed';

    final start = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  str3(
                    language,
                    'BO‘LIM SINOVI',
                    'ПРОВЕРКА РАЗДЕЛА',
                    'UNIT CHECKPOINT',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  unit.titleFor(language),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC800).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          passed
                              ? Icons.verified_rounded
                              : Icons.emoji_events_rounded,
                          size: 20,
                          color: const Color(0xFFFF9600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          passed
                              ? str3(
                                  language,
                                  'Muvaffaqiyatli topshirilgan',
                                  'Пройдено',
                                  'Passed',
                                )
                              : str3(
                                  language,
                                  'Bo‘limni yakunlash sinovi',
                                  'Итоговая проверка',
                                  'Final unit quiz',
                                ),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF9600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (locked) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          color: Colors.grey,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            str3(
                              language,
                              'Bo‘limdagi barcha darslarni tugating.',
                              'Завершите все уроки в этом разделе.',
                              'Complete all lessons in this unit.',
                            ),
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.grey.shade300
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      str3(language, 'QULFLANGAN', 'ЗАБЛОКИРОВАНО', 'LOCKED'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ] else ...[
                  _ThreeDButton(
                    color: const Color(0xFFFF9600),
                    shadowColor: const Color(0xFFCC7800),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(
                      passed
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (start != true || !context.mounted) return;
    await context.push(
      '/skills/practice',
      extra: {'mode': PracticeMode.checkpoint, 'unit_id': unit.id},
    );
    if (context.mounted) ref.invalidate(_treeProvider(subject.slug));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final treeAsync = ref.watch(_treeProvider(subject.slug));
    final subjectColor = _parseColor(subject.color);
    final userGoal = ref.watch(userDailyGoalProvider);
    final dailyGoal = userGoal > 0
        ? userGoal
        : (treeAsync.valueOrNull?.user.dailyGoalXp ?? 20);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: onChangeSubject == null,
        title: onChangeSubject == null
            ? Text(subject.nameFor(language))
            : TextButton.icon(
                onPressed: onChangeSubject,
                icon: const Icon(Icons.swap_horiz_rounded),
                label: Text(
                  subject.nameFor(language),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
        actions: [
          if (treeAsync.valueOrNull != null)
            IconButton(
              tooltip: str3(language, 'Bo‘limlar', 'Разделы', 'Sections'),
              onPressed: () =>
                  _sections(context, ref, treeAsync.requireValue, language),
              icon: const Icon(Icons.map_outlined),
            ),
          treeAsync.maybeWhen(
            data: (tree) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(child: HeartsXpHeader(summary: tree.user)),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: treeAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t('skills.error.generic', language)),
                TextButton(
                  onPressed: () => ref.invalidate(_treeProvider(subject.slug)),
                  child: Text(
                    str3(language, 'Qayta urinish', 'Повторить', 'Try again'),
                  ),
                ),
              ],
            ),
          ),
          data: (tree) {
            final items = <_PathItem>[];
            for (var uIdx = 0; uIdx < tree.units.length; uIdx++) {
              final unit = tree.units[uIdx];
              final hasUnpassedCheckpointBefore = tree.units
                  .take(uIdx)
                  .any((u) => u.examStatus != 'passed' && u.examStatus != 'none');
              for (var i = 0; i < unit.lessons.length; i++) {
                final l = unit.lessons[i];
                LessonLockReason? lockReason;
                if (l.status == LessonStatus.locked) {
                  lockReason = hasUnpassedCheckpointBefore
                      ? LessonLockReason.checkpointRequired
                      : LessonLockReason.previousLessonIncomplete;
                }
                items.add(
                  _PathItem.lesson(
                    lesson: l,
                    unitTitle: unit.titleFor(language),
                    unitStart: i == 0,
                    lockReason: lockReason,
                  ),
                );
              }
              if (unit.examStatus != 'none') {
                items.add(
                  _PathItem.checkpoint(
                    unit: unit,
                    unitTitle: unit.titleFor(language),
                  ),
                );
              }
            }
            final points = List.generate(
              items.length,
              (i) =>
                  Offset(_amplitude * math.sin(i * 0.9), 60 + i * _nodeSpacing),
            );
            final height = 60 + items.length * _nodeSpacing + 100;
            final firstUnlockedIndex = items.indexWhere(
              (it) =>
                  !it.isCheckpoint &&
                  it.lesson!.status == LessonStatus.unlocked,
            );

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final centerX = width / 2;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Material(
                          color: subjectColor,
                          borderRadius: BorderRadius.circular(20),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => showDailyGoalBottomSheet(
                              context: context,
                              ref: ref,
                              language: language,
                              accentColor: subjectColor,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        str3(
                                          language,
                                          'KUNLIK MAQSAD',
                                          'ЦЕЛЬ ДНЯ',
                                          'DAILY GOAL',
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.tune_rounded,
                                        color: Colors.white70,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    '${tree.user.todayXp}/$dailyGoal XP',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  LinearProgressIndicator(
                                    value: dailyGoal <= 0
                                        ? 0
                                        : (tree.user.todayXp / dailyGoal)
                                            .clamp(0.0, 1.0),
                                    color: Colors.white,
                                    backgroundColor: Colors.white24,
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                              if (firstUnlockedIndex >= 0) ...[
                                const SizedBox(height: 16),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF245700),
                                  ),
                                  onPressed: () async {
                                    await context.push(
                                      '/skills/lesson',
                                      extra: items[firstUnlockedIndex].lesson!,
                                    );
                                    if (context.mounted) {
                                      ref.invalidate(
                                        _treeProvider(subject.slug),
                                      );
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      str3(
                                        language,
                                        'DAVOM ETISH',
                                        'ПРОДОЛЖИТЬ',
                                        'CONTINUE',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  items[firstUnlockedIndex].lesson!.titleFor(
                                    language,
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                  textAlign: TextAlign.center,
                                ),
                              ] else ...[
                                const SizedBox(height: 12),
                                if (tree.units.any(
                                  (u) => u.examStatus == 'unlocked',
                                ))
                                  FilledButton.icon(
                                    onPressed: () =>
                                        _sections(context, ref, tree, language),
                                    icon: const Icon(
                                      Icons.emoji_events_rounded,
                                    ),
                                    label: Text(
                                      str3(
                                        language,
                                        'BO‘LIM SINOVI',
                                        'ПРОВЕРКА РАЗДЕЛА',
                                        'UNIT CHECKPOINT',
                                      ),
                                    ),
                                  ),
                                Text(
                                  str3(
                                    language,
                                    'Darslarni takrorlab bilimingizni mustahkamlang.',
                                    'Повторяйте уроки, чтобы закрепить знания.',
                                    'Revisit lessons to strengthen your knowledge.',
                                  ),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                      const Mascot(mood: MascotMood.idle, size: 64),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: width,
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _PathPainter(
                                  points: points,
                                  color: subjectColor,
                                ),
                              ),
                            ),
                            for (var i = 0; i < items.length; i++) ...[
                              if (items[i].unitStart)
                                Positioned(
                                  left: 16,
                                  right: 16,
                                  top: points[i].dy - 66,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: subjectColor,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        items[i].unitTitle.toUpperCase(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (i == firstUnlockedIndex &&
                                  !items[i].isCheckpoint)
                                Positioned(
                                  left: centerX + points[i].dx - 60,
                                  top: points[i].dy - 76,
                                  width: 120,
                                  child: Center(
                                    child: _FloatingStartIndicator(
                                      label: str3(
                                        language,
                                        'Boshlash',
                                        'Начать',
                                        'Start',
                                      ),
                                      color: subjectColor,
                                    ),
                                  ),
                                ),
                              Positioned(
                                left: centerX +
                                    points[i].dx -
                                    (items[i].isCheckpoint ? 36 : 32),
                                top: points[i].dy -
                                    (items[i].isCheckpoint ? 36 : 32),
                                child: _LessonNodeWidget(
                                  lesson: items[i].lesson,
                                  unit: items[i].unit,
                                  isCheckpoint: items[i].isCheckpoint,
                                  color: subjectColor,
                                  isCurrent: i == firstUnlockedIndex,
                                  onTap: () {
                                    if (items[i].isCheckpoint) {
                                      _showCheckpointPopover(
                                        context: context,
                                        ref: ref,
                                        unit: items[i].unit!,
                                        language: language,
                                        color: subjectColor,
                                      );
                                    } else {
                                      _showLessonPopover(
                                        context: context,
                                        ref: ref,
                                        lesson: items[i].lesson!,
                                        language: language,
                                        color: subjectColor,
                                        unitTitle: items[i].unitTitle,
                                        lockReason: items[i].lockReason,
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class LessonPopoverContent extends StatelessWidget {
  final SkillTreeLesson lesson;
  final String? unitTitle;
  final String language;
  final Color color;
  final VoidCallback? onStart;
  final LessonLockReason? lockReason;

  const LessonPopoverContent({
    super.key,
    required this.lesson,
    this.unitTitle,
    required this.language,
    required this.color,
    this.onStart,
    this.lockReason,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = lesson.status == LessonStatus.locked;
    final completed = lesson.status == LessonStatus.completed;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (unitTitle != null && unitTitle!.isNotEmpty) ...[
              Text(
                unitTitle!.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              lesson.titleFor(language),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white10
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Icon(
                          Icons.star_rounded,
                          size: 22,
                          color: completed && i <= lesson.stars
                              ? const Color(0xFFFFC800)
                              : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                        ),
                    ],
                  ),
                ),
                if (lesson.xpReward > 0) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9600).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: Color(0xFFFF9600),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${lesson.xpReward} XP',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF9600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            if (locked) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey.shade800
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.grey,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        lockReason?.message(language) ??
                            str3(
                              language,
                              'Oldingi darslar va bo‘lim sinovini tugating.',
                              'Завершите предыдущие уроки и проверку раздела.',
                              'Complete the earlier lessons and unit checkpoint.',
                            ),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade700,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  str3(language, 'QULFLANGAN', 'ЗАБЛОКИРОВАНО', 'LOCKED'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ] else ...[
              Text(
                str3(
                  language,
                  'Tushuntirish → mashq → xatolarni mustahkamlash',
                  'Объяснение → практика → работа над ошибками',
                  'Learn → practise → review mistakes',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 20),
              _ThreeDButton(
                color: completed ? const Color(0xFF1CB0F6) : color,
                shadowColor: completed
                    ? const Color(0xFF0D8AC4)
                    : _darken(color, 0.28),
                onPressed: onStart,
                child: Text(
                  completed
                      ? str3(
                          language,
                          'QAYTA O‘TISH',
                          'ПОВТОРИТЬ',
                          'PRACTISE AGAIN',
                        )
                      : str3(language, 'BOSHLASH', 'НАЧАТЬ', 'START'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FloatingStartIndicator extends StatefulWidget {
  final String label;
  final Color color;
  const _FloatingStartIndicator({required this.label, required this.color});

  @override
  State<_FloatingStartIndicator> createState() =>
      _FloatingStartIndicatorState();
}

class _FloatingStartIndicatorState extends State<_FloatingStartIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: widget.color,
              letterSpacing: 0.5,
            ),
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: widget.color),
        ),
      ],
    );

    if (reduceMotion) return bubble;

    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final dy = -4.0 * Curves.easeInOut.transform(_anim.value);
        return Transform.translate(
          offset: Offset(0, dy),
          child: child,
        );
      },
      child: bubble,
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LessonNodeWidget extends StatefulWidget {
  final SkillTreeLesson? lesson;
  final SkillTreeUnit? unit;
  final bool isCheckpoint;
  final Color color;
  final bool isCurrent;
  final VoidCallback onTap;

  const _LessonNodeWidget({
    this.lesson,
    this.unit,
    this.isCheckpoint = false,
    required this.color,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  State<_LessonNodeWidget> createState() => _LessonNodeWidgetState();
}

class _LessonNodeWidgetState extends State<_LessonNodeWidget> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bool locked;
    final bool completed;
    final int stars;

    if (widget.isCheckpoint) {
      locked = widget.unit?.examStatus == 'locked';
      completed = widget.unit?.examStatus == 'passed';
      stars = 0;
    } else {
      locked = widget.lesson?.status == LessonStatus.locked;
      completed = widget.lesson?.status == LessonStatus.completed;
      stars = widget.lesson?.stars ?? 0;
    }

    final Color bgColor;
    final Color shadowColor;
    final Color iconColor;
    final IconData iconData;

    if (widget.isCheckpoint) {
      iconData = locked
          ? Icons.lock_rounded
          : (completed ? Icons.verified_rounded : Icons.emoji_events_rounded);
      if (locked) {
        bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);
        shadowColor =
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFB0B0B0);
        iconColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade500;
      } else if (completed) {
        bgColor = const Color(0xFFFFC800);
        shadowColor = const Color(0xFFD69A00);
        iconColor = Colors.white;
      } else {
        bgColor = const Color(0xFFFF9600);
        shadowColor = const Color(0xFFCC7800);
        iconColor = Colors.white;
      }
    } else {
      iconData = locked
          ? Icons.lock_rounded
          : (completed ? Icons.check_rounded : Icons.star_rounded);
      if (locked) {
        bgColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5E5);
        shadowColor =
            isDark ? const Color(0xFF1C1C1E) : const Color(0xFFB0B0B0);
        iconColor = isDark ? const Color(0xFF8E8E93) : Colors.grey.shade500;
      } else if (completed) {
        bgColor = const Color(0xFFFFC800);
        shadowColor = const Color(0xFFD69A00);
        iconColor = Colors.white;
      } else {
        bgColor = widget.color;
        shadowColor = _darken(widget.color, 0.28);
        iconColor = Colors.white;
      }
    }

    final double nodeSize = widget.isCheckpoint ? 72.0 : 64.0;
    final double topOffset = _pressed ? 4.0 : 0.0;
    final double bottomBevel = _pressed ? 2.0 : 6.0;

    Widget node = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: Transform.translate(
        offset: Offset(0, topOffset),
        child: Container(
          width: nodeSize,
          height: nodeSize,
          decoration: BoxDecoration(
            shape: widget.isCheckpoint ? BoxShape.rectangle : BoxShape.circle,
            borderRadius:
                widget.isCheckpoint ? BorderRadius.circular(22) : null,
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                offset: Offset(0, bottomBevel),
                blurRadius: 0,
              ),
            ],
            border: Border.all(
              color: isDark && locked
                  ? Colors.white12
                  : Colors.white.withValues(alpha: 0.35),
              width: 3.5,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            iconData,
            color: iconColor,
            size: widget.isCheckpoint ? 34 : 30,
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        node,
        const SizedBox(height: 8),
        if (completed && stars > 0)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 1; i <= 3; i++)
                Icon(
                  Icons.star_rounded,
                  size: 13,
                  color: i <= stars
                      ? const Color(0xFFFFC800)
                      : Colors.grey.shade300,
                ),
            ],
          )
        else
          const SizedBox(height: 13),
      ],
    );
  }
}

class _ThreeDButton extends StatefulWidget {
  final Widget child;
  final Color color;
  final Color shadowColor;
  final VoidCallback? onPressed;

  const _ThreeDButton({
    required this.child,
    required this.color,
    required this.shadowColor,
    required this.onPressed,
  });

  @override
  State<_ThreeDButton> createState() => _ThreeDButtonState();
}

class _ThreeDButtonState extends State<_ThreeDButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final topOffset = _pressed ? 4.0 : 0.0;
    final bottomBevel = _pressed ? 2.0 : 6.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            }
          : null,
      child: Transform.translate(
        offset: Offset(0, topOffset),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: enabled ? widget.color : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: enabled ? widget.shadowColor : Colors.grey.shade500,
                offset: Offset(0, bottomBevel),
                blurRadius: 0,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PathPainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  _PathPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final centerX = size.width / 2;
    final path = Path()..moveTo(centerX + points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final midY = (prev.dy + curr.dy) / 2;
      path.quadraticBezierTo(
        centerX + prev.dx,
        midY,
        centerX + (prev.dx + curr.dx) / 2,
        midY,
      );
      path.quadraticBezierTo(
        centerX + curr.dx,
        midY,
        centerX + curr.dx,
        curr.dy,
      );
    }

    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, path, paint);
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    const dashWidth = 3.0;
    const dashGap = 12.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}

Color _darken(Color color, [double amount = .25]) {
  assert(amount >= 0 && amount <= 1);
  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
  return hslDark.toColor();
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF58CC02);
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
