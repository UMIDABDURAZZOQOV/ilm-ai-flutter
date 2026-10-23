import '../../../core/config/mobile_release.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import 'learning_journey_widgets.dart';
import 'study_start_sheet.dart';
import '../application/lesson_entry.dart';
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
    required SkillTreeUnit this.unit,
    required this.unitTitle,
    required this.unitStart,
    this.lockReason,
  }) : isCheckpoint = false;

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
  final bool embedded;
  final String? courseNote;
  final VoidCallback? onChangeSubject;
  const SkillPathScreen({
    super.key,
    required this.subject,
    this.grade,
    this.embedded = false,
    this.courseNote,
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
        entry: ref.read(lessonEntryProvider(lesson)),
        onStart: () => Navigator.pop(ctx, true),
      ),
    );
    if (start != true || !context.mounted) return;
    await context.push('/skills/lesson', extra: lesson);
    if (context.mounted) {
      ref.invalidate(lessonEntryProvider(lesson));
      ref.invalidate(_treeProvider((subject.slug, grade)));
    }
  }

  Future<void> _showCheckpointPopover({
    required BuildContext context,
    required WidgetRef ref,
    required SkillTreeUnit unit,
    required String language,
    required Color color,
  }) async {
    final start = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      builder: (ctx) => CheckpointPopoverContent(
        unit: unit,
        language: language,
        onStart: () => Navigator.pop(ctx, true),
      ),
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
      appBar: embedded
          ? null
          : AppBar(
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
                    onPressed: () => _sections(
                      context,
                      ref,
                      treeAsync.requireValue,
                      language,
                    ),
                    icon: const Icon(Icons.map_outlined),
                  ),
                treeAsync.maybeWhen(
                  data: (tree) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Center(
                      child: FittedBox(
                        child: HeartsXpHeader(summary: tree.user),
                      ),
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
                    unit: unit,
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
              (it) => it.isCheckpoint
                  ? it.unit!.examStatus == 'unlocked'
                  : it.lesson!.status == LessonStatus.unlocked,
            );

            final nextLesson =
                firstUnlockedIndex >= 0 &&
                    !items[firstUnlockedIndex].isCheckpoint
                ? items[firstUnlockedIndex].lesson
                : null;
            final nextCheckpoint =
                firstUnlockedIndex >= 0 &&
                    items[firstUnlockedIndex].isCheckpoint
                ? items[firstUnlockedIndex].unit
                : null;
            final entries = {
              for (final item in items.where((item) => !item.isCheckpoint))
                item.lesson!.id: item.lesson!.status == LessonStatus.unlocked
                    ? ref.watch(lessonEntryProvider(item.lesson!))
                    : LessonEntry.resolve(item.lesson!, null, DateTime.now()),
            };
            final hasCompleted = items.any(
              (item) => item.lesson?.status == LessonStatus.completed,
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
              child: LayoutBuilder(
                builder: (context, constraints) => CustomScrollView(
                  key: PageStorageKey(
                    'learning:${ref.watch(currentUserIdProvider)}:${subject.slug}:$grade',
                  ),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        ((constraints.maxWidth - IlmDesign.readingWidth) / 2)
                            .clamp(16, double.infinity),
                        12,
                        ((constraints.maxWidth - IlmDesign.readingWidth) / 2)
                            .clamp(16, double.infinity),
                        24,
                      ),
                      sliver: SliverList.builder(
                        itemCount: items.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LearningContinueCard(
                                  language: language,
                                  statusLabel: nextCheckpoint != null
                                      ? str3(
                                          language,
                                          'Bo‘lim sinoviga tayyor',
                                          'Можно пройти проверку',
                                          'Ready for the checkpoint',
                                        )
                                      : str3(
                                          language,
                                          'O‘quv yo‘lingiz',
                                          'Ваш учебный путь',
                                          'Your learning path',
                                        ),
                                  courseNote: courseNote,
                                  summary: embedded ? tree.user : null,
                                  entry: nextLesson == null
                                      ? null
                                      : entries[nextLesson.id],
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
                                      nextCheckpoint?.titleFor(language) ??
                                      (hasCompleted
                                          ? str3(
                                              language,
                                              'Takrorlash uchun dars tanlang',
                                              'Выберите урок для повторения',
                                              'Choose a lesson to practise again',
                                            )
                                          : str3(
                                              language,
                                              'Darslar yo‘li',
                                              'Путь обучения',
                                              'Learning path',
                                            )),
                                  todayXp: tree.user.todayXp,
                                  goalXp: dailyGoal,
                                  onGoal: () => showDailyGoalBottomSheet(
                                    context: context,
                                    ref: ref,
                                    language: language,
                                    accentColor: subjectColor,
                                  ),
                                  checkpoint: nextCheckpoint != null,
                                  onContinue: nextLesson != null
                                      ? () async {
                                          await context.push(
                                            '/skills/lesson',
                                            extra: nextLesson,
                                          );
                                          if (context.mounted) {
                                            ref.invalidate(
                                              lessonEntryProvider(nextLesson),
                                            );
                                            ref.invalidate(
                                              _treeProvider((
                                                subject.slug,
                                                grade,
                                              )),
                                            );
                                          }
                                        }
                                      : nextCheckpoint != null
                                      ? () => _showCheckpointPopover(
                                          context: context,
                                          ref: ref,
                                          unit: nextCheckpoint,
                                          language: language,
                                          color: subjectColor,
                                        )
                                      : null,
                                ),
                                if (items.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Text(
                                      str3(
                                        language,
                                        'Bu yo‘lda hozircha darslar yo‘q. Mavzular ro‘yxatini tekshiring yoki yangilang.',
                                        'На этом пути пока нет уроков. Проверьте темы или обновите страницу.',
                                        'There are no lessons on this path yet. Check the topics or refresh.',
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          }
                          final i = index - 1;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (items[i].unitStart ||
                                  (items[i].isCheckpoint &&
                                      (i == 0 ||
                                          items[i - 1].unitTitle !=
                                              items[i].unitTitle)))
                                LearningUnitHeader(
                                  title: items[i].unitTitle,
                                  language: language,
                                  completed: items[i].unit!.lessons
                                      .where(
                                        (lesson) =>
                                            lesson.status ==
                                            LessonStatus.completed,
                                      )
                                      .length,
                                  total: items[i].unit!.lessons.length,
                                  coverageComplete:
                                      items[i].unit!.coverageComplete,
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
                                        : items[i].isCheckpoint
                                        ? str3(language, 'Boshlash', 'Начать', 'Start')
                                        : entries[items[i].lesson!.id]!.description(language)}',
                                stateLabel: items[i].isCheckpoint
                                    ? items[i].unit!.examStatus == 'locked'
                                          ? str3(
                                              language,
                                              'Qulflangan',
                                              'Заблокировано',
                                              'Locked',
                                            )
                                          : items[i].unit!.examStatus ==
                                                'passed'
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
                                    : items[i].lesson!.status ==
                                          LessonStatus.locked
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
                                    : entries[items[i].lesson!.id]!.action(
                                        language,
                                      ),
                                locked: items[i].isCheckpoint
                                    ? items[i].unit!.examStatus == 'locked'
                                    : items[i].lesson!.status ==
                                          LessonStatus.locked,
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
                          );
                        },
                      ),
                    ),
                  ],
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
  final LessonEntry? entry;

  const LessonPopoverContent({
    super.key,
    required this.lesson,
    this.unitTitle,
    required this.language,
    required this.color,
    this.onStart,
    this.lockReason,
    this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    final locked = lesson.status == LessonStatus.locked;
    final completed = lesson.status == LessonStatus.completed;
    final presentation =
        entry ?? LessonEntry.resolve(lesson, null, DateTime.now());
    return StudyStartSheet(
      language: language,
      title: lesson.titleFor(language),
      contextLabel: unitTitle,
      icon: completed
          ? Icons.task_alt_rounded
          : presentation.state == LessonEntryState.resume
          ? Icons.bookmark_added_outlined
          : Icons.menu_book_outlined,
      details: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          if (completed)
            Chip(
              avatar: Icon(Icons.star_rounded, size: 18, color: c.warning),
              label: Text(
                str3(
                  language,
                  '${lesson.stars}/3 yulduz',
                  '${lesson.stars}/3 звёзд',
                  '${lesson.stars}/3 stars',
                ),
              ),
              backgroundColor: c.primaryLight,
              side: BorderSide.none,
            ),
          if (lesson.xpReward > 0)
            Chip(
              avatar: Icon(Icons.bolt_rounded, size: 18, color: c.warning),
              label: Text(
                '+${lesson.xpReward} XP',
                style: TextStyle(color: c.warning),
              ),
              backgroundColor: c.warningLight,
              side: BorderSide.none,
            ),
        ],
      ),
      description: str3(
        language,
        'Tushuntirish · mashq · xatolarni mustahkamlash',
        'Теория · практика · работа над ошибками',
        'Learn · practise · review mistakes',
      ),
      notice: locked
          ? lockReason?.message(language) ??
                str3(
                  language,
                  'Oldingi darslar va bo‘lim sinovini tugating.',
                  'Завершите предыдущие уроки и проверку раздела.',
                  'Complete the earlier lessons and unit checkpoint.',
                )
          : presentation.state == LessonEntryState.resume
          ? presentation.description(language)
          : presentation.state == LessonEntryState.expired
          ? str3(
              language,
              'Oldingi urinish muddati tugagan. Keyingi oynada yangi urinish boshlashingiz mumkin.',
              'Срок предыдущей попытки истёк. На следующем экране можно начать заново.',
              'The previous attempt has expired. You can start again on the next screen.',
            )
          : null,
      actionLabel: presentation.action(language),
      onStart: onStart,
      locked: locked,
    );
  }
}

Color _parseColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF2A1F6B);
  final cleaned = hex.replaceFirst('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
