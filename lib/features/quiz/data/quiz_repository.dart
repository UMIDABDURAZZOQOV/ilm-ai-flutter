import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'quiz_models.dart';

class QuizRepository {
  final Dio _dio;
  const QuizRepository(this._dio);

  Future<List<QuizQuestion>> generateQuiz({
    required int userId,
    required String difficulty,
    required int numQuestions,
    required String language,
    String? topic,
  }) async {
    final res = await _dio.post('/quiz/generate', data: {
      'user_id': userId,
      'difficulty': difficulty,
      'num_questions': numQuestions,
      'language': language,
      if (topic != null) 'topic': topic,
    });
    final data = res.data as Map<String, dynamic>;
    if (data['error'] != null) {
      throw Exception(data['error'].toString());
    }
    final questions = (data['questions'] as List? ?? []).map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
    if (questions.isEmpty) {
      throw Exception('No questions were generated. Please try again.');
    }
    return questions;
  }

  Future<int> completeQuiz({
    required int userId,
    required String difficulty,
    required int score,
    required int total,
    required List<QuizResultItem> results,
  }) async {
    final res = await _dio.post('/quiz/complete', data: {
      'user_id': userId,
      'difficulty': difficulty,
      'score': score,
      'total': total,
      'results': results.map((r) => r.toJson()).toList(),
    });
    return (res.data as Map<String, dynamic>)['session_id'] as int? ?? 0;
  }

  Future<QuizStats> getStats(int userId) async {
    final res = await _dio.get('/quiz/stats/$userId');
    return QuizStats.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Flashcard>> generateFlashcards(int userId, String language) async {
    final res = await _dio.post('/quiz/flashcards', data: {'user_id': userId, 'language': language});
    final data = res.data as Map<String, dynamic>;
    return (data['flashcards'] as List? ?? []).map((e) => Flashcard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ReviewItem>> getDueReviews(int userId) async {
    final res = await _dio.get('/review/due/$userId');
    final data = res.data as Map<String, dynamic>;
    return (data['due'] as List? ?? []).map((e) => ReviewItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ReviewItem> completeReview(int itemId, {required int userId, required int score, required int total}) async {
    final res = await _dio.post('/review/$itemId/complete', data: {'user_id': userId, 'score': score, 'total': total});
    return ReviewItem.fromJson(res.data as Map<String, dynamic>);
  }
}

final quizRepositoryProvider = Provider<QuizRepository>((ref) => QuizRepository(ref.watch(dioProvider)));
