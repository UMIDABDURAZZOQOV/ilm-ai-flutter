import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_providers.dart' show languageProvider;
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/premium_loading.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../auth/application/auth_controller.dart' show currentUserIdProvider;
import '../../quiz/data/quiz_models.dart';
import '../data/course_repository.dart';

String _tr(String lang, String uz, String ru, String en) =>
    lang == 'ru' ? ru : lang == 'en' ? en : uz;

class CourseScreen extends ConsumerStatefulWidget {
  const CourseScreen({super.key});
  @override
  ConsumerState<CourseScreen> createState() => _CourseScreenState();
}

class _CourseScreenState extends ConsumerState<CourseScreen> {
  CourseState? _state;
  bool _loading = true;
  bool _generating = false;
  String? _error;
  String? _openingKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    try {
      final s = await ref.read(courseRepositoryProvider).getCourse(userId);
      if (mounted) setState(() { _state = s; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _generate() async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    setState(() { _generating = true; _error = null; });
    try {
      final course = await ref.read(courseRepositoryProvider).generate(userId, lang);
      if (mounted) setState(() { _state = CourseState(course: course, completed: {}); });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().contains('no_materials') ? 'no_materials' : 'failed');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _openLesson(int ci, int li, CourseChapter ch, CourseLesson ls) async {
    final userId = ref.read(currentUserIdProvider);
    final lang = ref.read(languageProvider);
    if (userId == null) return;
    final key = 'c${ci}l$li';
    setState(() => _openingKey = key);
    try {
      final qs = await ref.read(courseRepositoryProvider).lessonQuestions(
            userId: userId,
            chapterTitle: ch.title,
            lessonTitle: ls.title,
            lessonSummary: ls.summary,
            language: lang,
          );
      if (qs.isEmpty || !mounted) return;
      final score = await Navigator.of(context).push<int>(MaterialPageRoute(
        builder: (_) => _LessonRunner(title: ls.title, questions: qs, lang: lang),
      ));
      if (score != null) {
        await ref.read(courseRepositoryProvider).completeLesson(userId, key, score);
        setState(() {
          final c = Map<String, bool>.from(_state!.completed)..[key] = true;
          _state = CourseState(course: _state!.course, completed: c);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'failed');
    } finally {
      if (mounted) setState(() => _openingKey = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final lang = ref.watch(languageProvider);
    final course = _state?.course;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back_rounded, color: colors.text, size: 24), onPressed: () => context.pop()),
        title: Text(_tr(lang, 'Materialdan kurs', 'Курс из материалов', 'Course from materials'),
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: _loading
          ? const Center(child: PremiumLoading())
          : course == null
              ? _buildEmpty(colors, lang)
              : _buildCourse(colors, lang, course),
    );
  }

  Widget _buildEmpty(ThemeColors colors, String lang) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(Icons.auto_awesome_rounded, size: 40, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(_tr(lang, 'Kurs hali yo\'q', 'Курса пока нет', 'No course yet'),
                style: TextStyle(color: colors.text, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
            const SizedBox(height: 8),
            Text(
              _error == 'no_materials'
                  ? _tr(lang, 'Avval material (PDF) yuklang.', 'Сначала загрузите материал.', 'Upload material first.')
                  : _error == 'failed'
                      ? _tr(lang, 'Bo\'lmadi — qayta urinib ko\'ring.', 'Не удалось — попробуйте снова.', 'Couldn\'t build it — try again.')
                      : _tr(lang, 'Yuklagan materialingizdan kurs yasang.', 'Постройте курс из материалов.', 'Build a course from your materials.'),
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.textSecondary, fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            PremiumButton(
              onPressed: _generating ? null : _generate,
              borderRadius: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_generating)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  else
                    const Icon(Icons.auto_awesome_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(_generating
                      ? _tr(lang, 'Yaratilyapti...', 'Создаётся...', 'Building...')
                      : _tr(lang, 'Kurs yaratish', 'Создать курс', 'Build course')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourse(ThemeColors colors, String lang, Course course) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(child: Text(course.title, style: TextStyle(color: colors.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
            AnimatedPressable(
              onTap: _generating ? null : _generate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(_tr(lang, 'Qayta', 'Заново', 'Rebuild'), style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...course.chapters.asMap().entries.map((ce) {
          final ci = ce.key;
          final ch = ce.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(
                    width: 32, height: 32, alignment: Alignment.center,
                    decoration: BoxDecoration(color: colors.primaryLight, shape: BoxShape.circle),
                    child: Text('${ci + 1}', style: TextStyle(color: colors.primary, fontSize: 14, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(ch.title, style: TextStyle(color: colors.text, fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: -0.3))),
                ]),
                const SizedBox(height: 12),
                ...ch.lessons.asMap().entries.map((le) {
                  final li = le.key;
                  final ls = le.value;
                  final key = 'c${ci}l$li';
                  final done = _state?.completed[key] == true;
                  final opening = _openingKey == key;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 8),
                    child: AnimatedPressable(
                      onTap: _openingKey != null ? null : () => _openLesson(ci, li, ch, ls),
                      child: PremiumCard(
                        borderRadius: 18,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40, alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: done ? colors.success : colors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: opening
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                                  : Icon(done ? Icons.check_rounded : Icons.menu_book_rounded,
                                      size: 20, color: done ? Colors.white : colors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ls.title, style: TextStyle(color: colors.text, fontSize: 15, fontWeight: FontWeight.w800)),
                                  if (ls.summary.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(ls.summary, style: TextStyle(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: (le.key * 50).ms, duration: 300.ms),
                  );
                }),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// One-question-at-a-time runner for a course lesson. Pops with the score % on
/// finish (or null if abandoned).
class _LessonRunner extends StatefulWidget {
  final String title;
  final List<QuizQuestion> questions;
  final String lang;
  const _LessonRunner({required this.title, required this.questions, required this.lang});
  @override
  State<_LessonRunner> createState() => _LessonRunnerState();
}

class _LessonRunnerState extends State<_LessonRunner> {
  int _i = 0;
  String? _selected;
  bool _answered = false;
  int _correct = 0;

  void _pick(String opt) {
    if (_answered) return;
    setState(() {
      _selected = opt;
      _answered = true;
      if (opt == widget.questions[_i].correctAnswer) _correct++;
    });
  }

  void _next() {
    if (_i + 1 >= widget.questions.length) {
      Navigator.of(context).pop(((_correct / widget.questions.length) * 100).round());
    } else {
      setState(() { _i++; _selected = null; _answered = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final q = widget.questions[_i];
    final lang = widget.lang;
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.close_rounded, color: colors.text), onPressed: () => Navigator.of(context).pop()),
        title: Text('${_i + 1}/${widget.questions.length}', style: TextStyle(color: colors.textSecondary, fontSize: 14)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_i + (_answered ? 1 : 0)) / widget.questions.length,
                  minHeight: 6,
                  backgroundColor: colors.border,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
              ),
              const SizedBox(height: 20),
              Text(q.question, style: TextStyle(color: colors.text, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: q.options.map((opt) {
                    final isCorrect = opt == q.correctAnswer;
                    final isPicked = opt == _selected;
                    Color border = colors.border;
                    Color bg = colors.card;
                    if (_answered && isCorrect) { border = colors.success; bg = colors.successLight; }
                    else if (_answered && isPicked && !isCorrect) { border = colors.error; bg = colors.errorLight; }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _pick(opt),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: border, width: 1.6),
                          ),
                          child: Text(opt, style: TextStyle(color: colors.text, fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_answered) ...[
                if (q.explanation.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(q.explanation, style: TextStyle(color: colors.textSecondary, fontSize: 13)),
                  ),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    _i + 1 >= widget.questions.length
                        ? _tr(lang, 'Tugatish', 'Завершить', 'Finish')
                        : _tr(lang, 'Davom etish', 'Далее', 'Continue'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
