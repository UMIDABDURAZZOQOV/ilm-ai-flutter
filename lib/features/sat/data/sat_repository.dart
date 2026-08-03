import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'sat_models.dart';

class SatRepository {
  final Dio _dio;
  const SatRepository(this._dio);

  Future<SatSkillTree> skillTree(int userId) async {
    final res = await _dio.get('/sat-ielts/skills/$userId', queryParameters: {'exam_type': 'SAT'});
    return SatSkillTree.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SatScore> score(int userId) async {
    final res = await _dio.get('/sat-ielts/score/$userId', queryParameters: {'exam_type': 'SAT'});
    return SatScore.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SatSessionStart> startSession({
    required int userId,
    String? domain,
    String? skill,
    String difficulty = 'medium',
    int numQuestions = 10,
  }) async {
    final res = await _dio.post('/sat-ielts/sessions/start', data: {
      'user_id': userId,
      'exam_type': 'SAT',
      'domain': ?domain,
      'skill': ?skill,
      'difficulty': difficulty,
      'num_questions': numQuestions,
      'session_type': 'practice',
    });
    return SatSessionStart.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> submitAnswer({required int sessionId, required int questionId, required String answer, required int elapsedMs}) async {
    await _dio.post('/sat-ielts/sessions/$sessionId/answer', data: {
      'question_id': questionId,
      'answer': answer,
      'elapsed_ms': elapsedMs,
    });
  }

  Future<SatSessionResult> completeSession(int sessionId) async {
    final res = await _dio.post('/sat-ielts/sessions/$sessionId/complete');
    return SatSessionResult.fromJson(res.data as Map<String, dynamic>);
  }
}

final satRepositoryProvider = Provider<SatRepository>((ref) => SatRepository(ref.watch(dioProvider)));
