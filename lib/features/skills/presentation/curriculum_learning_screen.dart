import 'package:flutter/material.dart';
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
    String tr(String uz, String ru, String en) => str3(lang, uz, ru, en);
    final grades = ref.watch(curriculumGradesProvider(widget.subject.slug));
    if (_legacy) {
      return SkillPathScreen(
        subject: widget.subject,
        onChangeSubject: () => setState(() => _legacy = false),
      );
    }
    final selected = ref.watch(
      selectedCurriculumGradeProvider(widget.subject.slug),
    );
    return grades.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const MascotImage(pose: MascotPose.thinking, size: 120),
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
                  child: MascotImage(pose: MascotPose.hello, size: 110),
                ),
                Text(
                  tr(
                    'Qaysi sinfdan boshlaymiz?',
                    'С какого класса начнём?',
                    'Which grade will you study?',
                  ),
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
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
                        leading: CircleAvatar(child: Text('${item.grade}')),
                        title: Text(
                          tr(
                            '${item.grade}-sinf — ${item.title}',
                            '${item.grade} класс — ${item.title}',
                            'Grade ${item.grade} — ${item.title}',
                          ),
                        ),
                        subtitle: Text(
                          item.sourceBlocked
                              ? tr(
                                  'Darslik tekshiruvi kutilmoqda',
                                  'Ожидается проверка учебника',
                                  'Textbook verification pending',
                                )
                              : item.readyLessons > 0
                              ? tr(
                                  '${item.readyLessons} ta dars mavjud',
                                  'Доступно уроков: ${item.readyLessons}',
                                  '${item.readyLessons} lesson(s) available',
                                )
                              : tr(
                                  'Mavzular xaritasi bor; darslar tayyorlanmoqda',
                                  'Карта тем готова; уроки готовятся',
                                  'Topics mapped; lessons in preparation',
                                ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _select(item.grade),
                      ),
                    ),
                  ),
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
          );
        }
        final current = active;
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
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _choosing = true),
                        icon: const Icon(Icons.school_rounded),
                        label: Text(
                          tr(
                            '${current.grade}-sinf',
                            '${current.grade} класс',
                            'Grade ${current.grade}',
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showOutline(current.grade),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(tr('Mavzular', 'Темы', 'Topics')),
                    ),
                  ],
                ),
              ),
              if (current.readyLessons > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    tr(
                      'Hozir ${current.readyLessons} ta dars mavjud.',
                      'Сейчас доступно уроков: ${current.readyLessons}.',
                      '${current.readyLessons} lesson(s) available.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
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
                        onChangeSubject: () => setState(() => _choosing = true),
                      )
                    : ListView(
                        padding: const EdgeInsets.all(24),
                        children: [
                          const MascotImage(
                            pose: MascotPose.explaining,
                            size: 130,
                          ),
                          Text(
                            current.sourceBlocked
                                ? tr(
                                    'Darslikni tekshirish kutilmoqda',
                                    'Ожидается проверка учебника',
                                    'Textbook verification is pending',
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
          loading: () => const Center(child: CircularProgressIndicator()),
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
              if (outline.chapters.isEmpty)
                Text(
                  tr(
                    'Manba hali o‘qilmagan; mavzular taxmin bilan to‘ldirilmaydi.',
                    'Источник ещё не прочитан; темы не заполняются предположениями.',
                    'The source is unread; topics will not be guessed.',
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
                          ? Icons.play_circle_outline_rounded
                          : Icons.menu_book_outlined,
                    ),
                    title: Text(topic.title),
                    subtitle: Text(
                      '${topic.printedStart ?? "?"}–${topic.printedEnd ?? "?"} ${tr('bet', 'стр.', 'pp.')} · ${topic.completed
                          ? tr('Bajarilgan', 'Завершено', 'Completed')
                          : topic.ready
                          ? tr('Dars mavjud', 'Урок доступен', 'Lesson available')
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
