import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/math_text.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/duo_chrome.dart';
import '../../../core/widgets/ai_explain_sheet.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'mascot.dart';
import 'skill_ui.dart';
import 'study_exit_guard.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/widgets/celebration_confetti.dart';

class SkillLessonScreen extends ConsumerStatefulWidget {
  final SkillTreeLesson lesson;
  const SkillLessonScreen({super.key, required this.lesson});

  @override
  ConsumerState<SkillLessonScreen> createState() => _SkillLessonScreenState();
}

// `learning` is the Duolingo-style teach-first phase: the lesson's theory
// cards are shown one at a time BEFORE any question appears.
enum _Phase { loading, learning, playing, error, finished }

class _SkillLessonScreenState extends ConsumerState<SkillLessonScreen> {
  _Phase _phase = _Phase.loading;
  int? _attemptId;
  List<TheoryCard> _theory = [];
  int _theoryIndex = 0;
  List<SkillQuestion> _questions = [];
  int _index = 0;
  String? _selected;
  bool _answered = false;
  bool _submitting = false;
  bool _saveFailed = false;
  final List<LessonResultItem> _results = [];
  final List<int> _mistakes = [];
  bool _reviewing = false;
  final Stopwatch _timer = Stopwatch()..start();
  LessonCompleteResult? _completion;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    try {
      final res = await ref
          .read(skillTreeRepositoryProvider)
          .startLesson(
            lessonId: widget.lesson.id,
            userId: userId,
            language: language,
          );
      if (!mounted) return;
      if (res.questions.isEmpty) {
        setState(() => _phase = _Phase.error);
        return;
      }
      setState(() {
        _attemptId = res.attemptId;
        _theory = res.theory;
        _questions = res.questions;
        _phase = _theory.isNotEmpty ? _Phase.learning : _Phase.playing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.error);
    }
  }

  void _nextTheoryCard() {
    if (_theoryIndex + 1 < _theory.length) {
      setState(() => _theoryIndex++);
    } else {
      setState(() => _phase = _Phase.playing);
    }
  }

  SkillQuestion get _current => _questions[_index];

  void _pick(String option) {
    if (_answered) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = option);
  }

  void _check() {
    final option = _selected;
    if (_answered || option == null) return;
    final isCorrect = option == _current.correctAnswer;
    if (isCorrect) {
      HapticFeedback.lightImpact();
      ref.read(soundServiceProvider).playCorrect();
    } else {
      HapticFeedback.mediumImpact();
      ref.read(soundServiceProvider).playIncorrect();
    }
    setState(() {
      _selected = option;
      _answered = true;
      if (!_reviewing) {
        if (!isCorrect) _mistakes.add(_index);
        _results.add(
          LessonResultItem(
            questionId: _current.id,
            userAnswer: option,
            isCorrect: isCorrect,
          ),
        );
      }
    });
  }

  Future<void> _next() async {
    if (_submitting || !_answered) return;
    if (_reviewing && _selected != _current.correctAnswer) {
      setState(() {
        _selected = null;
        _answered = false;
      });
      return;
    }
    if (!_reviewing && _index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    if (_mistakes.isNotEmpty) {
      setState(() {
        _reviewing = true;
        _index = _mistakes.removeAt(0);
        _selected = null;
        _answered = false;
      });
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _attemptId == null) return;
    setState(() {
      _submitting = true;
      _saveFailed = false;
    });
    try {
      final res = await ref
          .read(skillTreeRepositoryProvider)
          .completeLesson(
            lessonId: widget.lesson.id,
            userId: userId,
            attemptId: _attemptId!,
            results: _results,
          );
      if (!mounted) return;
      ref.read(soundServiceProvider).playLessonComplete();
      setState(() {
        _timer.stop();
        _completion = res;
        _phase = _Phase.finished;
      });
    } catch (_) {
      if (mounted) setState(() => _saveFailed = true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => StudyExitGuard(
    active: _phase != _Phase.finished && _phase != _Phase.error,
    saving: _submitting,
    language: ref.watch(languageProvider),
    child: _buildContent(context),
  );

  Widget _buildContent(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);

    if (_phase == _Phase.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_phase == _Phase.error) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MascotImage(pose: MascotPose.sad, size: 110),
                  const SizedBox(height: 16),
                  Text(
                    t('skills.error.generic', language),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  GradientButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(t('skills.back', language)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_phase == _Phase.learning) {
      final card = _theory[_theoryIndex];
      final learnProgress = (_theoryIndex + 1) / _theory.length;
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    Expanded(
                      child: DuoProgressBar(
                        value: learnProgress,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('skills.learn', language),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(
                        child: MascotImage(
                          pose: MascotPose.explaining,
                          size: 110,
                        ),
                      ),
                      if (looksLikeUntranslatedUzbek(
                        '${card.title} ${card.body} ${card.example ?? ''}',
                        language,
                      )) ...[
                        const SizedBox(height: 10),
                        ContentLanguageBadge(language: language),
                      ],
                      const SizedBox(height: 16),
                      Container(
                            key: ValueKey(_theoryIndex),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.35),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.title,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  card.body,
                                  style: TextStyle(
                                    fontSize: 15,
                                    height: 1.5,
                                    color: colors.text,
                                  ),
                                ),
                                if (card.example != null &&
                                    card.example!.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: colors.card,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: colors.accent.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t(
                                            'skills.example',
                                            language,
                                          ).toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1,
                                            color: colors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          card.example!,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            height: 1.4,
                                            color: colors.text,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                          .animate(key: ValueKey('theory_$_theoryIndex'))
                          .fadeIn(duration: 250.ms)
                          .slideX(
                            begin: 0.08,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Duo3DButton(
                  onPressed: _nextTheoryCard,
                  child: Text(
                    _theoryIndex + 1 < _theory.length
                        ? t('skills.lesson.continue', language)
                        : t('skills.start_quiz', language),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_phase == _Phase.finished && _completion != null) {
      final c = _completion!;
      return Scaffold(
        body: CelebrationConfetti(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MascotImage(
                      pose: (c.total > 0 && (100 * c.score / c.total) >= 80)
                          ? MascotPose.happy
                          : MascotPose.hello,
                      size: 180,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      c.stars > 0
                          ? t('skills.complete.title', language)
                          : str3(
                              language,
                              'Yana bir bor mashq qilamiz!',
                              'Попробуем ещё раз!',
                              'Let’s practise again!',
                            ),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ).animate().fadeIn(duration: 250.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 1; i <= 3; i++)
                          Icon(
                            Icons.star_rounded,
                            size: 32,
                            color: i <= c.stars
                                ? Colors.amber
                                : Colors.grey.shade300,
                          )
                              .animate()
                              .scale(
                                delay: (180 + i * 120).ms,
                                duration: 350.ms,
                                curve: Curves.easeOutBack,
                              ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatColumn(
                          value: '+${c.xpAwarded}',
                          label: 'XP',
                          color: Colors.amber.shade700,
                        ).animate().scale(delay: 350.ms, duration: 300.ms, curve: Curves.easeOutBack),
                        const SizedBox(width: 24),
                        _StatColumn(
                          value: '${c.score}/${c.total}',
                          label: t('skills.complete.correct', language),
                          color: Colors.green,
                        ).animate().scale(delay: 450.ms, duration: 300.ms, curve: Curves.easeOutBack),
                        const SizedBox(width: 24),
                        _StatColumn(
                          value: '${c.streakDays}',
                          label: t('skills.complete.streak', language),
                          color: Colors.orange,
                        ).animate().scale(delay: 550.ms, duration: 300.ms, curve: Curves.easeOutBack),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      str3(
                        language,
                        'Birinchi urinish aniqligi',
                        'Точность первой попытки',
                        'First-attempt accuracy',
                      ),
                      style: TextStyle(color: colors.textMuted),
                    ),
                    Text(
                      '${c.total == 0 ? 0 : (100 * c.score / c.total).round()}%  ·  ${_timer.elapsed.inMinutes}:${(_timer.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Duo3DButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: Text(t('skills.lesson.continue', language)),
                    ).animate().fadeIn(delay: 600.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final q = _current;
    final isCorrect = _selected == q.correctAnswer;
    final progress = _reviewing
        ? 1.0
        : (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: DuoProgressBar(
                      value: progress,
                      color: colors.secondary,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_reviewing) ...[
                      Text(
                        str3(
                          language,
                          'XATOLARNI MUSTAHKAMLASH',
                          'РАБОТА НАД ОШИБКАМИ',
                          'REVIEW YOUR MISTAKES',
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFCE82FF),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!_answered) ...[
                      const Center(
                        child: MascotImage(
                          pose: MascotPose.thinking,
                          size: 104,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (!_answered &&
                        looksLikeUntranslatedUzbek(q.questionText, language))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ContentLanguageBadge(language: language),
                      ),
                    Text(
                      cleanMath(q.questionText),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    for (final option in q.options)
                      DuoChoiceCard(
                        text: cleanMath(option),
                        answered: _answered,
                        selected: _selected == option,
                        isCorrectOption: option == q.correctAnswer,
                        onTap: () => _pick(option),
                      ),
                  ],
                ),
              ),
            ),
            if (!_answered)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Duo3DButton(
                  onPressed: _selected == null ? null : _check,
                  child: Text(
                    str3(language, 'TEKSHIRISH', 'ПРОВЕРИТЬ', 'CHECK'),
                  ),
                ),
              ),
            if (_saveFailed)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  str3(
                    language,
                    'Natija saqlanmadi. Davom etish tugmasi bilan qayta urinib ko‘ring.',
                    'Результат не сохранён. Нажмите «Продолжить», чтобы повторить.',
                    'Result not saved. Tap Continue to retry.',
                  ),
                  style: TextStyle(color: colors.error),
                ),
              ),
            if (_answered)
              Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isCorrect
                          ? colors.successLight
                          : colors.errorLight,
                      border: Border(
                        top: BorderSide(
                          color: isCorrect ? colors.success : colors.error,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * 0.25,
                          ),
                          child: SingleChildScrollView(
                            child: Row(
                              children: [
                                MascotImage(
                                  pose: isCorrect
                                      ? MascotPose.happy
                                      : MascotPose.sad,
                                  size: 100,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isCorrect
                                            ? t(
                                                'skills.lesson.correct',
                                                language,
                                              )
                                            : t(
                                                'skills.lesson.incorrect',
                                                language,
                                              ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                          color: isCorrect
                                              ? colors.success
                                              : colors.error,
                                        ),
                                      ),
                                      if (!isCorrect) ...[
                                        Text(
                                          cleanMath(q.correctAnswer),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: colors.text,
                                          ),
                                        ),
                                        if (!_reviewing)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              str3(
                                                language,
                                                'Bu savol oxirida yana chiqadi',
                                                'Этот вопрос появится снова в конце',
                                                'This question will appear again at the end',
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: colors.textMuted,
                                              ),
                                            ),
                                          ),
                                      ],
                                      if (q.explanation != null &&
                                          q.explanation!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            cleanMath(q.explanation!),
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: colors.textMuted,
                                            ),
                                          ),
                                        ),
                                      AiExplainButton(
                                        question: q.questionText,
                                        correctAnswer: q.correctAnswer,
                                        userAnswer: _selected,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Duo3DButton(
                          color: isCorrect ? colors.success : colors.error,
                          shadowColor: isCorrect
                              ? const Color(0xFF046C4E)
                              : const Color(0xFF9B1C1C),
                          onPressed: _submitting ? null : _next,
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(t('skills.lesson.continue', language)),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

