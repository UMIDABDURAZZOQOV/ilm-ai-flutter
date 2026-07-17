import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class GapItem {
  final String topic;
  final double weaknessScore;
  final String? recommendedAction;

  GapItem({required this.topic, required this.weaknessScore, this.recommendedAction});

  factory GapItem.fromJson(Map<String, dynamic> json) => GapItem(
        topic: json['topic'] as String? ?? '',
        weaknessScore: (json['weakness_score'] as num?)?.toDouble() ?? 0,
        recommendedAction: json['recommended_action'] as String?,
      );
}

class GapsReportResponse {
  final bool ready;
  final List<GapItem> gaps;
  final bool? isPremium;
  final String? message;

  GapsReportResponse({required this.ready, required this.gaps, this.isPremium, this.message});

  factory GapsReportResponse.fromJson(Map<String, dynamic> json) => GapsReportResponse(
        ready: json['ready'] as bool? ?? false,
        gaps: (json['gaps'] as List? ?? []).map((e) => GapItem.fromJson(e as Map<String, dynamic>)).toList(),
        isPremium: json['is_premium'] as bool?,
        message: json['message'] as String?,
      );
}

class GapsRepository {
  final Dio _dio;
  const GapsRepository(this._dio);

  Future<GapsReportResponse> getReport(int userId) async {
    final res = await _dio.get('/gaps/report/$userId');
    return GapsReportResponse.fromJson(res.data as Map<String, dynamic>);
  }
}

final gapsRepositoryProvider = Provider<GapsRepository>((ref) => GapsRepository(ref.watch(dioProvider)));
