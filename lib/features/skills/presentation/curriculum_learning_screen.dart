import 'package:ilm_ai_flutter/core/widgets/animated_ilmo.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/ilm_state_view.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/ilm_design.dart';
import '../../../core/widgets/duo_chrome.dart' show foregroundOn;
import '../../../core/config/mobile_release.dart';
import '../../../core/config/integrated_beta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/application/auth_controller.dart';
import '../application/learning_preferences.dart';
import '../data/curriculum_models.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'mascot.dart';
import 'skill_path_screen.dart';
import 'skill_ui.dart';
import '../../study_help/subject_tutor.dart';

final curriculumGradesProvider =
    FutureProvider.family<List<CurriculumGrade>, String>(
      (ref, subject) =>
          ref.watch(skillTreeRepositoryProvider).getGrades(subject),
    );

final curriculumOutlineProvider = FutureProvider.autoDispose
    .family<CurriculumOutline, (String, int)>((ref, key) {
      ref.watch(studyRevisionProvider);
      final user = ref.watch(currentUserIdProvider);
      if (user == null) throw StateError('not authenticated');
      return ref
          .watch(skillTreeRepositoryProvider)
          .getCurriculum(userId: user, subject: key.$1, grade: key.$2);
    });

final selectedCurriculumGradeProvider = StateProvider.family<int?, String>((
  ref,
  subject,
) {
  ref.watch(studyRevisionProvider);
  final user = ref.watch(currentUserIdProvider);
  return user == null
      ? null
      : int.tryParse(
          ref.read(prefsServiceProvider).getString('class_$user') ?? '',
        );
});

/// The catalogue comes from the backend. Unwritten lessons never become fake nodes.
class CurriculumLearningScreen extends ConsumerStatefulWidget {
  final SkillSubject subject;
  final VoidCallback onChangeSubject;
  const CurriculumLearningScreen({
    super.key,
    required this.subject,
    required this.onChangeSubject,
  });
  @override
  ConsumerState<CurriculumLearningScreen> createState() =>
      _CurriculumLearningScreenState();
}

class _CurriculumLearningScreenState
    extends ConsumerState<CurriculumLearningScreen> {
  bool _legacy = false;
  bool _choosing = false;
  bool _saving = false;

  Future<void> _select(int grade) async {
    final user = ref.read(currentUserIdProvider);
    if (user == null || _saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(learningPreferencesProvider).save(user, {
        'grade': '$grade',
      });
      if (!mounted || ref.read(currentUserIdProvider) != user) return;
      ref
              .read(
                selectedCurriculumGradeProvider(widget.subject.slug).notifier,
              )
              .state =
          grade;
      setState(() => _choosing = false);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              extractError(error, language: ref.read(languageProvider)),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    String tr(String uz, String ru, String en) => str3(lang, uz, ru, en);
    final grades = ref.watch(curriculumGradesProvider(widget.subject.slug));
    if (_legacy && !biologyOnly) {
      return SkillPathScreen(
        subject: widget.subject,
        onChangeSubject: () => setState(() => _legacy = false),
      );
    }
    final selected = ref.watch(
      selectedCurriculumGradeProvider(widget.subject.slug),
    );
    return grades.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => IlmLoadingView(language: lang),
      error: (error, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const AnimatedIlmo(pose: MascotPose.thinking, size: 168),
            Text(
              tr(
                'Sinf yo‘llarini yuklab bo‘lmadi',
                'Не удалось загрузить классы',
                'Could not load grade paths',
              ),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(extractError(error, language: lang)),
            FilledButton(
              onPressed: () =>
                  ref.invalidate(curriculumGradesProvider(widget.subject.slug)),
              child: Text(tr('Qayta urinish', 'Повторить', 'Retry')),
            ),
            if (!biologyOnly)
              TextButton(
                onPressed: () => setState(() => _legacy = true),
                child: Text(
                  tr(
                    'Oldingi umumiy yo‘l',
                    'Прежний общий путь',
                    'Previous shared path',
                  ),
                ),
              ),
            TextButton(
              onPressed: widget.onChangeSubject,
              child: Text(
                tr('Fanni almashtirish', 'Сменить предмет', 'Change subject'),
              ),
            ),
          ],
        ),
      ),
      data: (items) {
        CurriculumGrade? active;
        for (final item in items) {
          if (item.grade == selected) active = item;
        }
        if (active == null || _choosing) {
          return SafeArea(
            child: IlmReadingWidth(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.subject.nameFor(lang),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onChangeSubject,
                        child: Text(tr('Fanlar', 'Предметы', 'Subjects')),
                      ),
                    ],
                  ),
                  const Center(
                    child: AnimatedIlmo(pose: MascotPose.hello, size: 154),
                  ),
                  Text(
                    tr(
                      'Qaysi sinfdan boshlaymiz?',
                      'С какого класса начнём?',
                      'Which grade will you study?',
                    ),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(
                      'Har bir sinfning o‘quv yo‘li va progressi alohida. Darslar hozir o‘zbek tilida.',
                      'У каждого класса свой путь и прогресс. Уроки пока на узбекском.',
                      'Each grade has its own path and progress. Lessons are currently in Uzbek.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    Text(
                      tr(
                        'Sinf yo‘llari hali tayyorlanmoqda.',
                        'Пути классов готовятся.',
                        'Grade paths are being prepared.',
                      ),
                    ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Card(
                        child: ListTile(
                          enabled: !_saving,
                          selected: item.grade == selected,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(IlmRadius.card),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: item.grade == selected
                                ? colors.primary
                                : colors.primaryLight,
                            foregroundColor: item.grade == selected
                                ? foregroundOn(colors.primary)
                                : colors.primary,
                            child: Text('${item.grade}'),
                          ),
                          title: Text(
                            tr(
                              '${item.grade}-sinf — ${item.title}',
                              '${item.grade} класс — ${item.title}',
                              'Grade ${item.grade} — ${item.title}',
                            ),
                          ),
                          subtitle:
                              reviewedLearning &&
                                  item.readyLessons > 0 &&
                                  !item.sourceBlocked
                              ? null
                              : Text(
                                  item.sourceBlocked
                                      ? tr(
                                          'Darslar tayyorlanmoqda',
                                          'Уроки готовятся',
                                          'Lessons in preparation',
                                        )
                                      : item.readyLessons > 0
                                      ? tr(
                                          'Tayyor darslar: ${item.readyLessons}',
                                          'Подготовлено уроков: ${item.readyLessons}',
                                          'Lessons prepared: ${item.readyLessons}',
                                        )
                                      : tr(
                                          'Mavzular xaritasi bor; darslar tayyorlanmoqda',
                                          'Карта тем готова; уроки готовятся',
                                          'Topics mapped; lessons in preparation',
                                        ),
                                ),
                          trailing: Icon(
                            item.grade == selected
                                ? Icons.check_circle_rounded
                                : Icons.chevron_right_rounded,
                          ),
                          onTap: () => _select(item.grade),
                        ),
                      ),
                    ),
                  if (!biologyOnly)
                    TextButton(
                      onPressed: () => setState(() => _legacy = true),
                      child: Text(
                        tr(
                          'Oldingi umumiy yo‘lni ochish',
                          'Открыть прежний общий путь',
                          'Open the previous shared path',
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }
        final current = active;
        final screen = MediaQuery.sizeOf(context);
        final largeText = MediaQuery.textScalerOf(context).scale(16) >= 25;
        final compactToolbar =
            reviewedLearning &&
            (screen.height < 480 || (screen.width < 440 && largeText));
        final gradeButton = TextButton.icon(
          onPressed: reviewedLearning
              ? widget.onChangeSubject
              : () => setState(() => _choosing = true),
          icon: const Icon(Icons.school_rounded),
          label: Text(
            tr(
              '${widget.subject.nameFor(lang)} · ${current.grade}-sinf',
              '${widget.subject.nameFor(lang)} · ${current.grade} класс',
              '${widget.subject.nameFor(lang)} · Grade ${current.grade}',
            ),
            maxLines: compactToolbar ? 2 : null,
            overflow: compactToolbar ? TextOverflow.ellipsis : null,
          ),
        );
        Widget toolbarAction({
          Key? key,
          required String label,
          required IconData icon,
          required VoidCallback onPressed,
        }) {
          if (compactToolbar) {
            return IconButton(
              key: key,
              tooltip: label,
              onPressed: onPressed,
              icon: Icon(icon),
            );
          }
          return TextButton.icon(
            key: key,
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          );
        }

        return SafeArea(
          top: true,
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: reviewedLearning
                    ? _CompactLearnHeader(
                        label: tr(
                          '${widget.subject.nameFor(lang)} · ${current.grade}-sinf',
                          '${widget.subject.nameFor(lang)} · ${current.grade} класс',
                          '${widget.subject.nameFor(lang)} · Grade ${current.grade}',
                        ),
                        onSubject: widget.onChangeSubject,
                        topicsLabel: tr('Mavzular', 'Темы', 'Topics'),
                        onTopics: () => _showOutline(current.grade),
                        tutorLabel: tr(
                          'Ilmodan so‘rang',
                          'Спросить Илмо',
                          'Ask Ilmo',
                        ),
                        onTutor: current.readyLessons > 0
                            ? () => openSubjectTutor(
                                context,
                                language: lang,
                                subject: widget.subject.slug,
                                grade: current.grade,
                              )
                            : null,
                      )
                    : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (compactToolbar) gradeButton,
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        if (reviewedLearning)
                          toolbarAction(
                            key: const ValueKey('quick_subject_switch'),
                            onPressed: widget.onChangeSubject,
                            icon: Icons.swap_horiz_rounded,
                            label: tr('Fanlar', 'Предметы', 'Subjects'),
                          ),
                        if (!compactToolbar) gradeButton,
                        toolbarAction(
                          onPressed: () => _showOutline(current.grade),
                          icon: Icons.menu_book_outlined,
                          label: tr('Mavzular', 'Темы', 'Topics'),
                        ),
                        if (reviewedLearning && current.readyLessons > 0)
                          toolbarAction(
                            key: const ValueKey('subject_tutor_entry'),
                            onPressed: () => openSubjectTutor(
                              context,
                              language: lang,
                              subject: widget.subject.slug,
                              grade: current.grade,
                            ),
                            icon: Icons.chat_bubble_outline_rounded,
                            label: tr(
                              'Ilmodan so‘rang',
                              'Спросить Илмо',
                              'Ask Ilmo',
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: current.readyLessons > 0
                    ? SkillPathScreen(
                        key: ValueKey(
                          '${widget.subject.slug}:${current.grade}',
                        ),
                        subject: widget.subject,
                        grade: current.grade,
                        embedded: true,
                        courseNote: reviewedLearning
                            ? null
                            : tr(
                                'Tayyor darslar: ${current.readyLessons}',
                                'Подготовлено уроков: ${current.readyLessons}',
                                'Lessons prepared: ${current.readyLessons}',
                              ),
                        onChangeSubject: () => setState(() => _choosing = true),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const AnimatedIlmo(
                            pose: MascotPose.explaining,
                            size: 182,
                          ),
                          Text(
                            current.sourceBlocked
                                ? tr(
                                    'Darslar tayyorlanmoqda',
                                    'Уроки готовятся',
                                    'Lessons are in preparation',
                                  )
                                : tr(
                                    'Darslar tayyorlanmoqda',
                                    'Уроки готовятся',
                                    'Lessons are in preparation',
                                  ),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            tr(
                              'Tayyor bo‘lmagan darslar uchun savol yoki progress yaratilmaydi.',
                              'Для неготовых уроков вопросы и прогресс не создаются.',
                              'Unwritten lessons do not create questions or progress.',
                            ),
                          ),
                          TextButton(
                            onPressed: () => _showOutline(current.grade),
                            child: Text(
                              tr(
                                'Mavzular xaritasini ko‘rish',
                                'Посмотреть карту тем',
                                'View topic map',
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showOutline(int grade) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
      ),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: _CurriculumOutline(
            subject: widget.subject.slug,
            grade: grade,
            onNext: _select,
          ),
        ),
      ),
    );
  }
}

class _CurriculumOutline extends ConsumerWidget {
  final String subject;
  final int grade;
  final Future<void> Function(int) onNext;
  const _CurriculumOutline({
    required this.subject,
    required this.grade,
    required this.onNext,
  });
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    String tr(String uz, String ru, String en) => str3(lang, uz, ru, en);
    final key = (subject, grade);
    return ref
        .watch(curriculumOutlineProvider(key))
        .when(
          loading: () => IlmLoadingView(language: lang),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(extractError(error, language: lang)),
              FilledButton(
                onPressed: () => ref.invalidate(curriculumOutlineProvider(key)),
                child: Text(tr('Qayta urinish', 'Повторить', 'Retry')),
              ),
            ],
          ),
          data: (outline) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                tr(
                  '$grade-sinf mavzulari',
                  'Темы $grade класса',
                  'Grade $grade topics',
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              Text(
                tr(
                  'Bu mavzular xaritasi. Tayyor darslar o‘quv yo‘lida ketma-ket ochiladi.',
                  'Это карта тем. Подготовленные уроки открываются по порядку на учебном пути.',
                  'This is the topic map. Prepared lessons unlock in order on the learning path.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.route_outlined),
                  label: Text(
                    tr(
                      'Dars yo‘liga qaytish',
                      'Вернуться к урокам',
                      'Back to learning path',
                    ),
                  ),
                ),
              ),
              if (outline.chapters.isEmpty)
                Text(
                  tr(
                    'Mavzular tayyorlanmoqda.',
                    'Темы готовятся.',
                    'Topics are in preparation.',
                  ),
                ),
              for (final chapter in outline.chapters) ...[
                const SizedBox(height: 20),
                Text(
                  chapter.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                for (final topic in chapter.topics)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      topic.completed
                          ? Icons.check_circle_rounded
                          : topic.ready
                          ? Icons.menu_book_rounded
                          : Icons.menu_book_outlined,
                    ),
                    title: Text(topic.title),
                    subtitle: Text(
                      '${reviewedLearning ? '' : '${topic.printedStart ?? "?"}–${topic.printedEnd ?? "?"} ${tr('bet', 'стр.', 'pp.')} · '}${topic.completed
                          ? tr('Bajarilgan', 'Завершено', 'Completed')
                          : topic.ready
                          ? tr('Kontent tayyor', 'Контент подготовлен', 'Content prepared')
                          : tr('Kontent tayyorlanmoqda', 'Контент готовится', 'Content in preparation')}',
                    ),
                  ),
              ],
              if (outline.completed && outline.nextGrade != null)
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onNext(outline.nextGrade!);
                  },
                  child: Text(
                    tr(
                      'Keyingi sinfga o‘tish',
                      'Перейти в следующий класс',
                      'Continue to the next grade',
                    ),
                  ),
                ),
            ],
          ),
        );
  }
}


/// One compact row like Duolingo's top bar: the subject/grade chip opens the
/// switcher, then icon actions for the topic map and the subject tutor.
class _CompactLearnHeader extends StatelessWidget {
  const _CompactLearnHeader({
    required this.label,
    required this.onSubject,
    required this.topicsLabel,
    required this.onTopics,
    required this.tutorLabel,
    required this.onTutor,
  });
  final String label, topicsLabel, tutorLabel;
  final VoidCallback? onSubject, onTutor;
  final VoidCallback onTopics;
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!.colors;
    return Row(
      children: [
        Expanded(
          child: Material(
            key: const ValueKey('quick_subject_switch'),
            color: c.primaryLight,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onSubject,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Icon(Icons.school_rounded, color: c.primary, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: c.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(Icons.expand_more_rounded, color: c.primary),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        IconButton(
          key: const ValueKey('learning_topics'),
          tooltip: topicsLabel,
          onPressed: onTopics,
          icon: const Icon(Icons.menu_book_rounded),
        ),
        if (onTutor != null)
          IconButton.filledTonal(
            key: const ValueKey('subject_tutor_entry'),
            tooltip: tutorLabel,
            onPressed: onTutor,
            icon: const Icon(Icons.chat_bubble_rounded),
          ),
      ],
    );
  }
}
