import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../quiz/data/quiz_models.dart';

class SearchHit {
  final String filename;
  final String text;
  final double score;
  const SearchHit({required this.filename, required this.text, required this.score});
  factory SearchHit.fromJson(Map<String, dynamic> j) => SearchHit(
        filename: (j['filename'] ?? '').toString(),
        text: (j['text'] ?? '').toString(),
        score: ((j['score'] ?? 0) as num).toDouble(),
      );
}

class SearchResult {
  final List<SearchHit> results;
  final bool noMaterials;
  const SearchResult({required this.results, required this.noMaterials});
}

class StudioRepository {
  final Dio _dio;
  const StudioRepository(this._dio);

  Future<SearchResult> search(int userId, String query) async {
    final res = await _dio.post('/studio/search', data: {'user_id': userId, 'query': query});
    final data = res.data as Map<String, dynamic>;
    return SearchResult(
      results: ((data['results'] as List?) ?? [])
          .map((e) => SearchHit.fromJson(e as Map<String, dynamic>))
          .toList(),
      noMaterials: data['no_materials'] == true,
    );
  }

  Future<String> cheatSheet(int userId, String language) async {
    final res = await _dio.post('/studio/cheat-sheet', data: {'user_id': userId, 'language': language});
    return _md(res.data);
  }

  Future<String> translate(int userId, String language) async {
    final res = await _dio.post('/studio/translate', data: {'user_id': userId, 'language': language});
    return _md(res.data);
  }

  Future<List<QuizQuestion>> mock(int userId, String language, {int n = 15}) async {
    final res = await _dio.post('/studio/mock', data: {'user_id': userId, 'language': language, 'n': n});
    final data = res.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error'].toString());
    return ((data['questions'] as List?) ?? [])
        .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<({String title, String mermaid})> diagram(int userId, String topic, bool fromMaterials, String language) async {
    final res = await _dio.post('/studio/diagram',
        data: {'user_id': userId, 'topic': topic, 'from_materials': fromMaterials, 'language': language});
    final data = res.data as Map<String, dynamic>;
    if (data['error'] != null) throw Exception(data['error'].toString());
    return (title: (data['title'] ?? '').toString(), mermaid: (data['mermaid'] ?? '').toString());
  }

  String _md(dynamic data) {
    final m = data as Map<String, dynamic>;
    if (m['error'] != null) throw Exception(m['error'].toString());
    return (m['markdown'] ?? '').toString();
  }
}

final studioRepositoryProvider =
    Provider<StudioRepository>((ref) => StudioRepository(ref.watch(dioProvider)));
