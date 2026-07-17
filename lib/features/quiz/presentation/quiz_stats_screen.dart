import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quiz_repository.dart';

final _statsProvider = FutureProvider.autoDispose((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;
  return ref.read(quizRepositoryProvider).getStats(userId);
});

class QuizStatsScreen extends ConsumerWidget {
  const QuizStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final statsAsync = ref.watch(_statsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('quiz.stats.title', language))),
      body: SafeArea(
        child: statsAsync.when(
          data: (stats) {
            if (stats == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(child: _Stat(value: '${stats.sessionsCompleted}', label: t('quiz.stats.sessions', language), colors: colors)),
                    const SizedBox(width: 10),
                    Expanded(child: _Stat(value: '${stats.averageScore.round()}%', label: t('quiz.stats.avg.score', language), colors: colors)),
                    const SizedBox(width: 10),
                    Expanded(child: _Stat(value: '${stats.correctAnswers}', label: t('quiz.stats.correct', language), colors: colors)),
                  ],
                ),
                const SizedBox(height: 24),
                if (stats.topicsCovered.isNotEmpty) ...[
                  Text(t('quiz.stats.topics', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: stats.topicsCovered
                        .map((topic) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(color: colors.primaryLight, borderRadius: BorderRadius.circular(20)),
                              child: Text(topic, style: TextStyle(color: colors.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 24),
                ],
                if (stats.scoreTrend.isNotEmpty) ...[
                  Text(t('quiz.stats.recent', language), style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                  const SizedBox(height: 10),
                  for (final item in stats.scoreTrend.reversed.take(10))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 90, child: Text(item.date, style: TextStyle(fontSize: 12, color: colors.textMuted))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(value: item.scorePct / 100, backgroundColor: colors.border, color: colors.primary, minHeight: 8),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${item.scorePct.round()}%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: colors.text)),
                        ],
                      ),
                    ),
                ],
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(extractError(e), style: TextStyle(color: colors.error))),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final ThemeColors colors;

  const _Stat({required this.value, required this.label, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: colors.border)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: colors.text)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 11, color: colors.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
