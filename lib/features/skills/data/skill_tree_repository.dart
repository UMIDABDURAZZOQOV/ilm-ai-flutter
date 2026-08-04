import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'skill_tree_models.dart';

class SkillTreeRepository {
  final Dio _dio;
  const SkillTreeRepository(this._dio);

  Future<List<SkillSubject>> getSubjects() async {
    final res = await _dio.get('/skills/subjects');
    return (res.data as List).map((e) => SkillSubject.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SkillTreeResponse> getTree({required int userId, required String subjectSlug}) async {
    final res = await _dio.get('/skills/$userId/tree', queryParameters: {'subject': subjectSlug});
    return SkillTreeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GamificationSummary> getSummary(int userId) async {
    final res = await _dio.get('/skills/$userId/summary');
    return GamificationSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LessonStartResult> startLesson({required int lessonId, required int userId, String language = 'uz'}) async {
    try {
      final res = await _dio.post('/skills/lessons/$lessonId/start', data: {'user_id': userId, 'language': language});
      return LessonStartResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data is Map ? (e.response!.data as Map)['detail'] : null;
      if (detail == 'locked') {
        throw LessonLockedException();
      }
      rethrow;
    }
  }

  Future<LessonCompleteResult> completeLesson({
    required int lessonId,
    required int userId,
    required int attemptId,
    required List<LessonResultItem> results,
  }) async {
    final res = await _dio.post('/skills/lessons/$lessonId/complete', data: {
      'user_id': userId,
      'attempt_id': attemptId,
      'results': results.map((r) => r.toJson()).toList(),
    });
    return LessonCompleteResult.fromJson(res.data as Map<String, dynamic>);
  }
}

final skillTreeRepositoryProvider = Provider<SkillTreeRepository>((ref) => SkillTreeRepository(ref.watch(dioProvider)));
