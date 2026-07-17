import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'plan_models.dart';

class PlanRepository {
  final Dio _dio;
  const PlanRepository(this._dio);

  Future<LearningPlan> getPlan(int userId) async {
    final res = await _dio.get('/plan/$userId');
    return LearningPlan.fromJson(res.data as Map<String, dynamic>);
  }

  Future<TodayPlanResponse> getTodayPlan(int userId) async {
    final res = await _dio.get('/plan/$userId/today');
    return TodayPlanResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<LearningPlan> generatePlan({
    required int userId,
    required double dailyHours,
    required String goal,
    required String targetDate,
  }) async {
    final res = await _dio.post('/plan/generate', data: {
      'user_id': userId,
      'daily_hours': dailyHours,
      'goal': goal,
      'target_date': targetDate,
    });
    return LearningPlan.fromJson(res.data as Map<String, dynamic>);
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) => PlanRepository(ref.watch(dioProvider)));
