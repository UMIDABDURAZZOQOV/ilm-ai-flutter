import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/math_text.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

class QuizSessionScreen extends ConsumerStatefulWidget {
  final List<QuizQuestion> questions;
  final String difficulty;
  final String language;
  final int? reviewItemId;

  const QuizSessionScreen({
    super.key,
    required this.questions,
    required this.difficulty,
    required this.language,
    this.reviewItemId,
  });

  @override
  ConsumerState<QuizSessionScreen> createState() => _QuizSessionScreenState();
}

class _QuizSessionScreenState extends ConsumerState<QuizSessionScreen> {
  int _index = 0;
  String? _selected;
  bool _answered = false;
  final List<QuizResultItem> _results = [];
  bool _submitting = false;

  QuizQuestion get _current => widget.questions[_index];

  void _selectOption(String option) {
    if (_answered) return;
    setState(() {
      _selected = option;
      _answered = true;
      _results.add(QuizResultItem(
        question: _current.question,
        userAnswer: option,
        correctAnswer: _current.correctAnswer,
        isCorrect: option == _current.correctAnswer,
        topic: _current.topic,
        explanation: _current.explanation,
      ));
    });
  }

  Future<void> _next() async {
    if (_index == widget.questions.length - 1) {
      await _finish();
      return;
    }
    setState(() {
      _index++;
      _selected = null;
      _answered = false;
    });
  }

  Future<void> _finish() async {
    final userId = ref.read(currentUserIdProvider);
    final score = _results.where((r) => r.isCorrect).length;
    final total = _results.length;
    setState(() => _submitting = true);
    try {
      if (userId != null) {
        await ref.read(quizRepositoryProvider).completeQuiz(
              userId: userId,
              difficulty: widget.difficulty,
              score: score,
              total: total,
              results: _results,
            );
        if (widget.reviewItemId != null) {
          await ref.read(quizRepositoryProvider).completeReview(widget.reviewItemId!, userId: userId, score: score, total: total);
        }
      }
    } catch (_) {
      // best-effort submission -- still show the result screen
    }
    if (mounted) {
      context.pushReplacement('/quiz/result', extra: {'score': score, 'total': total, 'results': _results});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final progress = (_index + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('quiz.progress', language).replaceAll('{n}', '${_index + 1}').replaceAll('{t}', '${widget.questions.length}'), 
            style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.3)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(value: progress, backgroundColor: colors.border, color: colors.primary, minHeight: 8),
              ),
              const SizedBox(height: 28),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(cleanMath(_current.question), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: colors.text, height: 1.5, letterSpacing: -0.3)),
                      const SizedBox(height: 24),
                      for (final option in _current.options.asMap().entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OptionTile(
                            option: option.value,
                            state: !_answered
                                ? _OptionState.neutral
                                : option.value == _current.correctAnswer
                                    ? _OptionState.correct
                                    : option.value == _selected
                                        ? _OptionState.incorrect
                                        : _OptionState.disabled,
                            colors: colors,
                            onTap: () => _selectOption(option.value),
                          ).animate().fadeIn(delay: (option.key * 50).ms, duration: 300.ms),
                        ),
                      if (_answered && _current.explanation.isNotEmpty)
                        PremiumCard(
                          margin: const EdgeInsets.only(top: 16),
                          backgroundColor: colors.primaryLight,
                          borderRadius: 18,
                          padding: const EdgeInsets.all(18),
                          child: Text(cleanMath(_current.explanation), style: TextStyle(color: colors.text, fontSize: 15, height: 1.5, fontWeight: FontWeight.w500)),
                        ).animate().fadeIn(delay: 200.ms, duration: 300.ms),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PremiumButton(
                onPressed: !_answered || _submitting ? null : _next,
                loading: _submitting,
                borderRadius: 20,
                child: Text(_index == widget.questions.length - 1 ? t('quiz.finish', language) : t('quiz.next', language)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptionState { neutral, correct, incorrect, disabled }

class _OptionTile extends StatelessWidget {
  final String option;
  final _OptionState state;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _OptionTile({required this.option, required this.state, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color border = colors.border;
    Color bg = colors.card;
    Color text = colors.text;
    IconData? icon;
    Color? iconColor;

    switch (state) {
      case _OptionState.neutral:
        break;
      case _OptionState.correct:
        border = colors.success;
        bg = colors.successLight;
        icon = Icons.check_circle_rounded;
        iconColor = colors.success;
        break;
      case _OptionState.incorrect:
        border = colors.error;
        bg = colors.errorLight;
        text = colors.error;
        icon = Icons.cancel_rounded;
        iconColor = colors.error;
        break;
      case _OptionState.disabled:
        text = colors.textMuted;
        break;
    }

    return AnimatedPressable(
      onTap: state == _OptionState.neutral ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: border, width: state == _OptionState.neutral ? 1.5 : 2),
        ),
        child: Row(
          children: [
            Expanded(child: Text(cleanMath(option), style: TextStyle(color: text, fontWeight: FontWeight.w700, fontSize: 15))),
            if (icon != null) Icon(icon, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }
}
