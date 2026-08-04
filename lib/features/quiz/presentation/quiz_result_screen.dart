import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/ai_explain_sheet.dart';
import '../../../core/utils/math_text.dart';
import '../data/quiz_models.dart';

/// Ported from ilm-ai-mobile's QuizResultScreen.tsx: a spring-physics score
/// reveal (scale+fade in) followed by staggered fade-ins for each result
/// row, mirroring the reanimated withSpring/withDelay sequence.
class QuizResultScreen extends ConsumerStatefulWidget {
  final int score;
  final int total;
  final List<QuizResultItem> results;

  const QuizResultScreen({super.key, required this.score, required this.total, required this.results});

  @override
  ConsumerState<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends ConsumerState<QuizResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scoreScale;
  late final Animation<double> _scoreOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _scoreScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.7, curve: Curves.elasticOut)),
    );
    _scoreOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeOut)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final pct = widget.total == 0 ? 0 : (widget.score / widget.total * 100).round();
    final resultLabel = pct >= 80 ? t('quiz.result.excellent', language) : pct >= 50 ? t('quiz.result.good', language) : t('quiz.result.keep', language);

    return Scaffold(
      appBar: AppBar(title: Text(t('quiz.result.title', language)), automaticallyImplyLeading: false),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _scoreOpacity.value,
                child: Transform.scale(scale: _scoreScale.value, child: child),
              ),
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(colors: [colors.primary, colors.secondary]),
                ),
                child: Column(
                  children: [
                    Text('$pct%', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 6),
                    Text(resultLabel, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Text(
                      t('quiz.result.progress.label', language).replaceAll('{score}', '${widget.score}').replaceAll('{total}', '${widget.total}'),
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            for (var i = 0; i < widget.results.length; i++) _AnimatedResultRow(index: i, controller: _controller, result: widget.results[i], colors: colors, language: language),
            const SizedBox(height: 8),
            GradientButton(
              // The result was pushReplacement'd over the quiz home, so a plain
              // pop returns there cleanly. `go('/quiz')` left the pushed page in
              // the branch stack, which reappeared as the "old question" loop.
              onPressed: () => context.canPop() ? context.pop() : context.go('/quiz'),
              child: Text(t('common.back', language)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedResultRow extends StatelessWidget {
  final int index;
  final AnimationController controller;
  final QuizResultItem result;
  final ThemeColors colors;
  final String language;

  const _AnimatedResultRow({required this.index, required this.controller, required this.result, required this.colors, required this.language});

  @override
  Widget build(BuildContext context) {
    final start = (0.45 + index * 0.08).clamp(0.0, 0.9);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final fade = CurvedAnimation(parent: controller, curve: Interval(start, end, curve: Curves.easeOut));

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: fade.value,
        child: Transform.translate(offset: Offset(0, (1 - fade.value) * 16), child: child),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(result.isCorrect ? Icons.check_circle : Icons.cancel, color: result.isCorrect ? colors.success : colors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(cleanMath(result.question), style: TextStyle(fontWeight: FontWeight.w600, color: colors.text))),
              ],
            ),
            const SizedBox(height: 8),
            Text('${t('quiz.result.your.answer', language)}: ${result.userAnswer}', style: TextStyle(color: result.isCorrect ? colors.success : colors.error, fontSize: 13)),
            if (!result.isCorrect) Text('${t('quiz.result.correct.answer', language)}: ${result.correctAnswer}', style: TextStyle(color: colors.success, fontSize: 13)),
            const SizedBox(height: 2),
            AiExplainButton(question: result.question, correctAnswer: result.correctAnswer, userAnswer: result.userAnswer),
          ],
        ),
      ),
    );
  }
}
