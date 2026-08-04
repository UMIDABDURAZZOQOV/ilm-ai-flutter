import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/skill_tree_models.dart';
import '../data/skill_tree_repository.dart';
import 'mascot.dart';

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
  final List<LessonResultItem> _results = [];
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
      final res = await ref.read(skillTreeRepositoryProvider).startLesson(lessonId: widget.lesson.id, userId: userId, language: language);
      setState(() {
        _attemptId = res.attemptId;
        _theory = res.theory;
        _questions = res.questions;
        _phase = _theory.isNotEmpty ? _Phase.learning : _Phase.playing;
      });
    } catch (_) {
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
    final isCorrect = option == _current.correctAnswer;
    setState(() {
      _selected = option;
      _answered = true;
      _results.add(LessonResultItem(questionId: _current.id, userAnswer: option, isCorrect: isCorrect));
    });
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
        _answered = false;
      });
      return;
    }
    final userId = ref.read(currentUserIdProvider);
    if (userId == null || _attemptId == null) return;
    try {
      final res = await ref.read(skillTreeRepositoryProvider).completeLesson(
            lessonId: widget.lesson.id,
            userId: userId,
            attemptId: _attemptId!,
            results: _results,
          );
      setState(() {
        _completion = res;
        _phase = _Phase.finished;
      });
    } catch (_) {
      setState(() => _phase = _Phase.error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Mascot(mood: MascotMood.sad, size: 100),
                  const SizedBox(height: 16),
                  Text(t('skills.error.generic', language), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  GradientButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('skills.back', language))),
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(value: learnProgress, minHeight: 10, backgroundColor: colors.border, color: const Color(0xFF1CB0F6)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(t('skills.learn', language), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: colors.textMuted)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Center(child: Mascot(mood: MascotMood.happy, size: 80)),
                      const SizedBox(height: 20),
                      Container(
                        key: ValueKey(_theoryIndex),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1CB0F6).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFF1CB0F6).withValues(alpha: 0.35), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF1489C1))),
                            const SizedBox(height: 10),
                            Text(card.body, style: TextStyle(fontSize: 15, height: 1.5, color: colors.text)),
                            if (card.example != null && card.example!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: colors.card,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFF1CB0F6).withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t('skills.example', language).toUpperCase(),
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: Color(0xFF1CB0F6))),
                                    const SizedBox(height: 4),
                                    Text(card.example!, style: TextStyle(fontSize: 13.5, height: 1.4, color: colors.text)),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ).animate(key: ValueKey('theory_$_theoryIndex')).fadeIn(duration: 250.ms).slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: GradientButton(
                  onPressed: _nextTheoryCard,
                  child: Text(_theoryIndex + 1 < _theory.length ? t('skills.lesson.continue', language) : t('skills.start_quiz', language)),
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
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Mascot(mood: MascotMood.cheer, size: 140),
                  const SizedBox(height: 16),
                  Text(t('skills.complete.title', language), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 1; i <= 3; i++)
                        Icon(Icons.star_rounded, size: 32, color: i <= c.stars ? Colors.amber : Colors.grey.shade300),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatColumn(value: '+${c.xpAwarded}', label: 'XP', color: Colors.amber.shade700),
                      const SizedBox(width: 24),
                      _StatColumn(value: '${c.score}/${c.total}', label: t('skills.complete.correct', language), color: Colors.green),
                      const SizedBox(width: 24),
                      _StatColumn(value: '${c.streakDays}', label: t('skills.complete.streak', language), color: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 24),
                  GradientButton(onPressed: () => Navigator.of(context).pop(), child: Text(t('skills.lesson.continue', language))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final q = _current;
    final isCorrect = _selected == q.correctAnswer;
    final progress = (_index + (_answered ? 1 : 0)) / _questions.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.of(context).pop()),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: colors.border, color: const Color(0xFF58CC02)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(q.questionText, textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.text, height: 1.4)),
                    const SizedBox(height: 24),
                    for (final option in q.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _OptionTile(
                          option: option,
                          answered: _answered,
                          isSelected: _selected == option,
                          isCorrectOption: option == q.correctAnswer,
                          colors: colors,
                          onTap: () => _pick(option),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_answered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isCorrect ? colors.successLight : colors.errorLight,
                  border: Border(top: BorderSide(color: isCorrect ? colors.success : colors.error, width: 2)),
                ),
                child: Row(
                  children: [
                    Mascot(mood: isCorrect ? MascotMood.happy : MascotMood.sad, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCorrect ? t('skills.lesson.correct', language) : t('skills.lesson.incorrect', language),
                            style: TextStyle(fontWeight: FontWeight.w800, color: isCorrect ? colors.success : colors.error),
                          ),
                          if (q.explanation != null && q.explanation!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(q.explanation!, style: TextStyle(fontSize: 13, color: colors.textMuted)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GradientButton(onPressed: _next, child: Text(t('skills.lesson.continue', language))),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
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
  const _StatColumn({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String option;
  final bool answered;
  final bool isSelected;
  final bool isCorrectOption;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _OptionTile({
    required this.option,
    required this.answered,
    required this.isSelected,
    required this.isCorrectOption,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color border = colors.border;
    Color bg = colors.card;
    Color text = colors.text;

    if (answered) {
      if (isCorrectOption) {
        border = colors.success;
        bg = colors.successLight;
      } else if (isSelected) {
        border = colors.error;
        bg = colors.errorLight;
        text = colors.error;
      } else {
        text = colors.textMuted;
      }
    }

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: answered ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border, width: 2)),
        child: Text(option, style: TextStyle(color: text, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
