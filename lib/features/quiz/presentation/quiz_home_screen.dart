import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/animated_pressable.dart';
import '../../../core/widgets/duo_icon.dart';
import '../../../core/widgets/error_banner.dart';
import '../../../core/widgets/premium_card.dart';
import '../../../core/widgets/premium_button.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quiz_repository.dart';

final _dueReviewCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return 0;
  try {
    final due = await ref.read(quizRepositoryProvider).getDueReviews(userId);
    return due.length;
  } catch (_) {
    return 0;
  }
});

class QuizHomeScreen extends ConsumerStatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  ConsumerState<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends ConsumerState<QuizHomeScreen> {
  String _difficulty = 'medium';
  int _numQuestions = 5;
  bool _generating = false;
  String? _error;

  Future<void> _startQuiz() async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    setState(() {
      _generating = true;
      _error = null;
    });
    try {
      final questions = await ref.read(quizRepositoryProvider).generateQuiz(
            userId: userId,
            difficulty: _difficulty,
            numQuestions: _numQuestions,
            language: language,
          );
      if (mounted) {
        context.push('/quiz/session', extra: {'questions': questions, 'difficulty': _difficulty, 'language': language});
      }
    } catch (e) {
      setState(() => _error = extractError(e));
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final dueCount = ref.watch(_dueReviewCountProvider).valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(t('quiz.title', language), style: TextStyle(color: colors.text, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ErrorBanner(message: _error, onDismiss: () => setState(() => _error = null)),
              Row(
                children: [
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.bar_chart_rounded,
                      label: t('quiz.stats.title', language),
                      colors: colors,
                      onTap: () => context.push('/quiz/stats'),
                    ).animate().fadeIn(duration: 280.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.style_rounded,
                      label: t('flashcard.title', language),
                      colors: colors,
                      onTap: () => context.push('/quiz/flashcards'),
                    ).animate().fadeIn(delay: 60.ms, duration: 280.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickLink(
                      icon: Icons.replay_circle_filled_rounded,
                      label: t('review.title', language),
                      badge: dueCount > 0 ? dueCount : null,
                      colors: colors,
                      onTap: () => context.push('/quiz/review'),
                    ).animate().fadeIn(delay: 120.ms, duration: 280.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(t('quiz.difficulty', language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.text, fontSize: 16, letterSpacing: -0.3)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final d in ['easy', 'medium', 'hard'])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: d != 'hard' ? 10 : 0),
                        child: _Chip(
                          label: t('quiz.difficulty.$d', language),
                          selected: _difficulty == d,
                          colors: colors,
                          onTap: () => setState(() => _difficulty = d),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(t('quiz.questions.count', language), style: TextStyle(fontWeight: FontWeight.w800, color: colors.text, fontSize: 16, letterSpacing: -0.3)),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final n in [5, 10])
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: n != 10 ? 10 : 0),
                        child: _Chip(label: '$n', selected: _numQuestions == n, colors: colors, onTap: () => setState(() => _numQuestions = n)),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 36),
              PremiumButton(
                onPressed: _generating ? null : _startQuiz,
                loading: _generating,
                borderRadius: 20,
                child: Text(t('quiz.start', language)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final int? badge;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _QuickLink({required this.icon, required this.label, this.badge, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressable(
      onTap: onTap,
      child: PremiumCard(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                DuoIcon(icon, color: colors.primary, size: 28),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: colors.error, borderRadius: BorderRadius.circular(10)),
                      child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 12, color: colors.textSecondary, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeColors colors;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.selected, required this.colors, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? colors.primary : colors.border, width: 1.5),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(color: selected ? Colors.white : colors.text, fontWeight: FontWeight.w800, fontSize: 15),
          child: Text(label),
        ),
      ),
    );
  }
}
