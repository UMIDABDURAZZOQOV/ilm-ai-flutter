import '../../../core/config/mobile_release.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import 'learning_journey_widgets.dart';
import '../../../core/widgets/ilm_state_view.dart';
import '../../../core/network/error_message.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'hearts_xp_widgets.dart';
import 'skill_ui.dart';
import 'skill_practice_screen.dart';
import 'daily_goal_bottom_sheet.dart';

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
  }) : isCheckpoint = false,
       unit = null;

  _PathItem.checkpoint({
    required SkillTreeUnit this.unit,
    required this.unitTitle,
  }) : isCheckpoint = true,
       lesson = null,
       unitStart = false,
       lockReason = null;
}

final _treeProvider = FutureProvider.autoDispose
    .family<SkillTreeResponse, (String, int?)>((ref, key) async {
      ref.watch(studyRevisionProvider);
      final userId = ref.watch(currentUserIdProvider);
      if (userId == null) throw Exception('not authenticated');
      return ref
          .read(skillTreeRepositoryProvider)
          .getTree(userId: userId, subjectSlug: key.$1, grade: key.$2);
    });

class SkillPathScreen extends ConsumerWidget {
  final SkillSubject subject;
  final int? grade;
  final VoidCallback? onChangeSubject;
  const SkillPathScreen({
    super.key,
    required this.subject,
    this.grade,
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
              if (!biologyOnly)
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
    if (context.mounted) ref.invalidate(_treeProvider((subject.slug, grade)));
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
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
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
    if (context.mounted) ref.invalidate(_treeProvider((subject.slug, grade)));
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
          child: SingleChildScrollView(
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
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
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
                          Flexible(
                            child: Text(
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
                                color: Color(0xFF2A1F6B),
                              ),
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
                              !unit.coverageComplete
                                  ? str3(
                                      language,
                                      'Bobning qolgan darslari tayyorlanmoqda. Checkpoint hali ochilmaydi.',
                                      'Остальные уроки главы готовятся. Проверка пока недоступна.',
                                      'The remaining chapter lessons are in preparation. The checkpoint is not available yet.',
                                    )
                                  : str3(
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
                    Duo3DButton(
                      color: const Color(0xFFF9A825),
                      shadowColor: const Color(0xFFC77700),
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
          ),
        );
      },
    );

    if (start != true || !context.mounted) return;
    await context.push(
      '/skills/practice',
      extra: {'mode': PracticeMode.checkpoint, 'unit_id': unit.id},
    );
    if (context.mounted) ref.invalidate(_treeProvider((subject.slug, grade)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(languageProvider);
    final treeAsync = ref.watch(_treeProvider((subject.slug, grade)));
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
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: FittedBox(child: HeartsXpHeader(summary: tree.user)),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: treeAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => IlmLoadingView(language: language),
          error: (error, _) => IlmStateView(
            title: t('skills.error.generic', language),
            message: extractError(error, language: language),
            retryLabel: str3(
              language,
              'Qayta urinish',
              'Повторить',
              'Try again',
            ),
            onRetry: () => ref.invalidate(_treeProvider((subject.slug, grade))),
          ),
          data: (tree) {
            final items = <_PathItem>[];
            for (var uIdx = 0; uIdx < tree.units.length; uIdx++) {
              final unit = tree.units[uIdx];
              final hasUnpassedCheckpointBefore = tree.units
                  .take(uIdx)
                  .any(
                    (u) => u.examStatus != 'passed' && u.examStatus != 'none',
                  );
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
            final firstUnlockedIndex = items.indexWhere(
              (it) =>
                  !it.isCheckpoint &&
                  it.lesson!.status == LessonStatus.unlocked,
            );

            final nextLesson = firstUnlockedIndex >= 0
                ? items[firstUnlockedIndex].lesson
                : null;
            final checkpointReady = tree.units.any(
              (u) => u.examStatus == 'unlocked',
            );
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(_treeProvider((subject.slug, grade)));
                try {
                  await ref.read(_treeProvider((subject.slug, grade)).future);
                } catch (_) {
                  // AsyncValue renders the localized error and retry action.
                  // A failed pull-to-refresh must still finish its indicator.
                }
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: IlmReadingWidth(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LearningContinueCard(
                        language: language,
                        contentNote:
                            subject.slug == 'biologiya' &&
                                grade != null &&
                                language != 'uz'
                            ? str3(
                                language,
                                'Dars tili: o‘zbekcha',
                                'Язык уроков: узбекский',
                                'Lesson language: Uzbek',
                              )
                            : null,
                        title:
                            nextLesson?.titleFor(language) ??
                            str3(
                              language,
                              'Bilimingizni mustahkamlang',
                              'Закрепите знания',
                              'Strengthen your knowledge',
                            ),
                        todayXp: tree.user.todayXp,
                        goalXp: dailyGoal,
                        onGoal: () => showDailyGoalBottomSheet(
                          context: context,
                          ref: ref,
                          language: language,
                          accentColor: subjectColor,
                        ),
                        checkpoint: nextLesson == null && checkpointReady,
                        onContinue: nextLesson != null
                            ? () async {
                                await context.push(
                                  '/skills/lesson',
                                  extra: nextLesson,
                                );
                                if (context.mounted) {
                                  ref.invalidate(
                                    _treeProvider((subject.slug, grade)),
                                  );
                                }
                              }
                            : checkpointReady
                            ? () => _sections(context, ref, tree, language)
                            : null,
                      ),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            str3(
                              language,
                              'Bu yo‘lda hozircha darslar yo‘q. Mavzular ro‘yxatini tekshiring yoki yangilang.',
                              'На этом пути пока нет уроков. Проверьте темы или обновите страницу.',
                              'There are no lessons on this path yet. Check the topics or refresh.',
                            ),
                          ),
                        ),
                      for (var i = 0; i < items.length; i++) ...[
                        if (items[i].unitStart ||
                            (items[i].isCheckpoint &&
                                (i == 0 ||
                                    items[i - 1].unitTitle !=
                                        items[i].unitTitle)))
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 12),
                            child: Text(
                              items[i].unitTitle.toUpperCase(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        LearningJourneyTile(
                          title: items[i].isCheckpoint
                              ? str3(
                                  language,
                                  'Bo‘lim sinovi',
                                  'Проверка раздела',
                                  'Unit checkpoint',
                                )
                              : items[i].lesson!.titleFor(language),
                          semanticLabel:
                              '${items[i].isCheckpoint ? items[i].unit!.titleFor(language) : items[i].lesson!.titleFor(language)}. ${(items[i].isCheckpoint ? items[i].unit!.examStatus == 'locked' : items[i].lesson!.status == LessonStatus.locked)
                                  ? str3(language, 'Qulflangan', 'Заблокировано', 'Locked')
                                  : (items[i].isCheckpoint ? items[i].unit!.examStatus == 'passed' : items[i].lesson!.status == LessonStatus.completed)
                                  ? str3(language, 'Bajarilgan', 'Завершено', 'Completed')
                                  : str3(language, 'Boshlash', 'Начать', 'Start')}',
                          stateLabel: items[i].isCheckpoint
                              ? items[i].unit!.examStatus == 'locked'
                                    ? str3(
                                        language,
                                        'Qulflangan',
                                        'Заблокировано',
                                        'Locked',
                                      )
                                    : items[i].unit!.examStatus == 'passed'
                                    ? str3(
                                        language,
                                        'Bajarilgan',
                                        'Завершено',
                                        'Completed',
                                      )
                                    : str3(
                                        language,
                                        'Boshlash',
                                        'Начать',
                                        'Start',
                                      )
                              : items[i].lesson!.status == LessonStatus.locked
                              ? str3(
                                  language,
                                  'Qulflangan',
                                  'Заблокировано',
                                  'Locked',
                                )
                              : items[i].lesson!.status ==
                                    LessonStatus.completed
                              ? str3(
                                  language,
                                  'Bajarilgan',
                                  'Завершено',
                                  'Completed',
                                )
                              : str3(language, 'BOSHLASH', 'НАЧАТЬ', 'START'),
                          locked: items[i].isCheckpoint
                              ? items[i].unit!.examStatus == 'locked'
                              : items[i].lesson!.status == LessonStatus.locked,
                          completed: items[i].isCheckpoint
                              ? items[i].unit!.examStatus == 'passed'
                              : items[i].lesson!.status ==
                                    LessonStatus.completed,
                          current: i == firstUnlockedIndex,
                          checkpoint: items[i].isCheckpoint,
                          stars: items[i].lesson?.stars ?? 0,
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
                      ],
                    ],
                  ),
                ),
              ),
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
    final colors = Theme.of(context).extension<AppColors>()!.colors;
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
                  color: colors.textSecondary,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              lesson.titleFor(language),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
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
                      color: colors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          size: 18,
                          color: colors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${lesson.xpReward} XP',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: colors.warning,
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
                  color: colors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border),
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
                  'Tushuntirish · mashq · xatolarni mustahkamlash',
                  'Теория · практика · работа над ошибками',
                  'Learn · practise · review mistakes',
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
              const SizedBox(height: 20),
              Duo3DButton(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
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

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF2A1F6B);
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
