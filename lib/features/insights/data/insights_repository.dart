import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class TopicStat {
  final String topic;
  final int accuracy;
  final int attempts;
  const TopicStat({required this.topic, required this.accuracy, required this.attempts});

  factory TopicStat.fromJson(Map<String, dynamic> j) => TopicStat(
        topic: (j['topic'] ?? '').toString(),
        accuracy: (j['accuracy'] ?? 0) as int,
        attempts: (j['attempts'] ?? 0) as int,
      );
}

class Insights {
  final bool hasData;
  final List<String> files;
  final int materialsCount;
  final int sessions;
  final int overallPct;
  final int trend;
  final List<int> recentScores;
  final List<TopicStat> strong;
  final List<TopicStat> weak;

  const Insights({
    required this.hasData,
    required this.files,
    required this.materialsCount,
    required this.sessions,
    required this.overallPct,
    required this.trend,
    required this.recentScores,
    required this.strong,
    required this.weak,
  });

  factory Insights.fromJson(Map<String, dynamic> j) {
    final materials = (j['materials'] as Map?) ?? {};
    final quiz = (j['quiz'] as Map?) ?? {};
    return Insights(
      hasData: j['has_data'] == true,
      files: ((materials['files'] as List?) ?? []).map((e) => e.toString()).toList(),
      materialsCount: (materials['count'] ?? 0) as int,
      sessions: (quiz['sessions'] ?? 0) as int,
      overallPct: (quiz['overall_pct'] ?? 0) as int,
      trend: (quiz['trend'] ?? 0) as int,
      recentScores: ((quiz['recent_scores'] as List?) ?? []).map((e) => (e as num).toInt()).toList(),
      strong: ((j['strong_topics'] as List?) ?? []).map((e) => TopicStat.fromJson(e as Map<String, dynamic>)).toList(),
      weak: ((j['weak_topics'] as List?) ?? []).map((e) => TopicStat.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class InsightsRepository {
  final Dio _dio;
  const InsightsRepository(this._dio);

  Future<Insights> getInsights(int userId) async {
    final res = await _dio.get('/insights/$userId');
    return Insights.fromJson(res.data as Map<String, dynamic>);
  }
}

final insightsRepositoryProvider =
    Provider<InsightsRepository>((ref) => InsightsRepository(ref.watch(dioProvider)));
