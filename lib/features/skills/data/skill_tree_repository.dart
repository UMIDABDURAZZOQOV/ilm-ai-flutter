import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_contract.dart';
import 'skill_tree_models.dart';
import 'curriculum_models.dart';
import '../../../core/config/mobile_release.dart';

class SkillTreeRepository {
  final Dio _dio;
  const SkillTreeRepository(this._dio);

  Future<List<SkillSubject>> getSubjects() async {
    late Response res;
    try {
      res = await _dio.get(
        '/skills/subjects',
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiCompatibilityException();
      }
      rethrow;
    }
    if (res.data is! List ||
        (res.data as List).any((item) => item is! Map<String, dynamic>)) {
      throw const InvalidApiResponseException();
    }
    try {
      return (res.data as List)
          .map((e) => SkillSubject.fromJson(e as Map<String, dynamic>))
          .where((s) => isPublishedMobileSubject(s.slug))
          .toList();
    } on TypeError {
      throw const InvalidApiResponseException();
    } on FormatException {
      throw const InvalidApiResponseException();
    }
  }

  Future<SkillTreeResponse> getTree({
    required int userId,
    required String subjectSlug,
    int? grade,
  }) async {
    final res = await _dio.get(
      '/skills/$userId/tree',
      queryParameters: {'subject': subjectSlug, 'grade': ?grade},
    );
    return SkillTreeResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<CurriculumGrade>> getGrades(String subject) async {
    final res = await _dio.get('/skills/subjects/$subject/grades');
    return ((res.data as Map<String, dynamic>)['grades'] as List)
        .map((g) => CurriculumGrade.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<CurriculumOutline> getCurriculum({
    required int userId,
    required String subject,
    int? grade,
  }) async {
    final res = await _dio.get(
      '/skills/$userId/curriculum',
      queryParameters: {'subject': subject, 'grade': grade},
    );
    return CurriculumOutline.fromJson(res.data as Map<String, dynamic>);
  }

  Future<GamificationSummary> getSummary(int userId) async {
    final res = await _dio.get('/skills/$userId/summary');
    return GamificationSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LessonStartResult> startLesson({
    required int lessonId,
    required int userId,
    String language = 'uz',
  }) async {
    try {
      final res = await _dio.post(
        '/skills/lessons/$lessonId/start',
        data: {'user_id': userId, 'language': language},
      );
      return LessonStartResult.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final detail = e.response?.data is Map
          ? (e.response!.data as Map)['detail']
          : null;
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
    final res = await _dio.post(
      '/skills/lessons/$lessonId/complete',
      data: {
        'user_id': userId,
        'attempt_id': attemptId,
        'results': results.map((r) => r.toJson()).toList(),
      },
    );
    return LessonCompleteResult.fromJson(res.data as Map<String, dynamic>);
  }
}

final skillTreeRepositoryProvider = Provider<SkillTreeRepository>(
  (ref) => SkillTreeRepository(ref.watch(dioProvider)),
);
