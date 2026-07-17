import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/network/error_message.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/application/auth_controller.dart';
import '../data/quiz_models.dart';
import '../data/quiz_repository.dart';

final _dueReviewsProvider = FutureProvider.autoDispose<List<ReviewItem>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];
  return ref.read(quizRepositoryProvider).getDueReviews(userId);
});

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key});

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  int? _startingItemId;

  Future<void> _startReview(ReviewItem item) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    final language = ref.read(languageProvider);
    setState(() => _startingItemId = item.id);
    try {
      final questions = await ref.read(quizRepositoryProvider).generateQuiz(
            userId: userId,
            difficulty: 'medium',
            numQuestions: 5,
            language: language,
            topic: item.topic,
          );
      if (mounted) {
        context.push('/quiz/session', extra: {
          'questions': questions,
          'difficulty': 'medium',
          'language': language,
          'reviewItemId': item.id,
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractError(e))));
    } finally {
      if (mounted) setState(() => _startingItemId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!.colors;
    final language = ref.watch(languageProvider);
    final dueAsync = ref.watch(_dueReviewsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t('review.title', language))),
      body: SafeArea(
        child: dueAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(t('review.empty', language), textAlign: TextAlign.center, style: TextStyle(color: colors.textMuted)),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: items.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: colors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: colors.border)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.topic, style: TextStyle(fontWeight: FontWeight.w700, color: colors.text)),
                            const SizedBox(height: 4),
                            Text('${t('review.stage', language)} ${item.intervalStage}', style: TextStyle(fontSize: 12, color: colors.textMuted)),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 90,
                        child: ElevatedButton(
                          onPressed: _startingItemId != null ? null : () => _startReview(item),
                          style: ElevatedButton.styleFrom(backgroundColor: colors.primary, foregroundColor: Colors.white),
                          child: _startingItemId == item.id
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(t('review.start', language)),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(extractError(e), style: TextStyle(color: colors.error))),
        ),
      ),
    );
  }
}
