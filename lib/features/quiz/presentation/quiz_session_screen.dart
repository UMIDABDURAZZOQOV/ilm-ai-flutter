import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
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
      appBar: AppBar(title: Text(t('quiz.progress', language).replaceAll('{n}', '${_index + 1}').replaceAll('{t}', '${widget.questions.length}'))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(value: progress, backgroundColor: colors.border, color: colors.primary, minHeight: 6),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_current.question, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colors.text, height: 1.4)),
                      const SizedBox(height: 20),
                      for (final option in _current.options)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _OptionTile(
                            option: option,
                            state: !_answered
                                ? _OptionState.neutral
                                : option == _current.correctAnswer
                                    ? _OptionState.correct
                                    : option == _selected
                                        ? _OptionState.incorrect
                                        : _OptionState.disabled,
                            colors: colors,
                            onTap: () => _selectOption(option),
                          ),
                        ),
                      if (_answered && _current.explanation.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(12)),
                          child: Text(_current.explanation, style: TextStyle(color: colors.text, fontSize: 13.5, height: 1.4)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GradientButton(
                onPressed: !_answered || _submitting ? null : _next,
                loading: _submitting,
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
        icon = Icons.check_circle;
        iconColor = colors.success;
        break;
      case _OptionState.incorrect:
        border = colors.error;
        bg = colors.errorLight;
        text = colors.error;
        icon = Icons.cancel;
        iconColor = colors.error;
        break;
      case _OptionState.disabled:
        text = colors.textMuted;
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: state == _OptionState.neutral ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12), border: Border.all(color: border, width: 1.5)),
        child: Row(
          children: [
            Expanded(child: Text(option, style: TextStyle(color: text, fontWeight: FontWeight.w600))),
            if (icon != null) Icon(icon, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}
