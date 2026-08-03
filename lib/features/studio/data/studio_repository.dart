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
    try {
      final res = await _dio.post('/studio/mock', data: {'user_id': userId, 'language': language, 'n': n});
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      return ((data['questions'] as List?) ?? [])
          .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  Future<({String title, String mermaid})> diagram(int userId, String topic, bool fromMaterials, String language) async {
    try {
      final res = await _dio.post('/studio/diagram',
          data: {'user_id': userId, 'topic': topic, 'from_materials': fromMaterials, 'language': language});
      final data = res.data as Map<String, dynamic>;
      if (data['error'] != null) throw Exception(data['error'].toString());
      return (title: (data['title'] ?? '').toString(), mermaid: (data['mermaid'] ?? '').toString());
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  /// Pulls the FastAPI `detail` string out of an error response so the UI can
  /// distinguish 'no_materials' from a generic failure.
  String _detail(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) return data['detail'].toString();
    return 'failed';
  }

  /// Spoken-style recap script (read aloud client-side via TTS).
  Future<({String script, List<String> sources})> audioRecap(int userId, String language, {String? filename}) async {
    try {
      final res = await _dio.post('/studio/audio-recap',
          data: {'user_id': userId, 'language': language, 'filename': ?filename});
      final data = res.data as Map<String, dynamic>;
      return (
        script: (data['script'] ?? '').toString(),
        sources: ((data['sources'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  /// Two-host podcast script — a list of {speaker, text} turns.
  Future<({String title, List<({String speaker, String text})> turns})> podcast(int userId, String language, {String? filename}) async {
    try {
      final res = await _dio.post('/studio/podcast',
          data: {'user_id': userId, 'language': language, 'filename': ?filename});
      final data = res.data as Map<String, dynamic>;
      final turns = ((data['script'] as List?) ?? [])
          .map((e) => (speaker: (e['speaker'] ?? 'A').toString(), text: (e['text'] ?? '').toString()))
          .toList();
      return (title: (data['title'] ?? '').toString(), turns: turns);
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  /// Concept map — nodes grouped by theme, plus edges between them.
  Future<KnowledgeMap> knowledgeMap(int userId, String language) async {
    try {
      final res = await _dio.post('/studio/knowledge-map', data: {'user_id': userId, 'language': language});
      return KnowledgeMap.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  /// Photograph a page → full study kit (summary, flashcards, quiz).
  Future<PhotoKit> photoKit(int userId, String language, String filePath) async {
    try {
      final form = FormData.fromMap({
        'user_id': userId,
        'language': language,
        'image': await MultipartFile.fromFile(filePath),
      });
      final res = await _dio.post('/studio/photo-kit', data: form);
      return PhotoKit.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  /// Photograph notes and add them to the RAG library. Returns how many chunks landed.
  Future<int> uploadNotesImage(int userId, String filePath, {String topic = 'Notes'}) async {
    try {
      final form = FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      final res = await _dio.post('/files/upload-image',
          queryParameters: {'user_id': userId, 'topic': topic}, data: form);
      final data = res.data as Map<String, dynamic>;
      return (data['chunks'] ?? data['chunks_added'] ?? 0) as int;
    } on DioException catch (e) {
      throw Exception(_detail(e));
    }
  }

  Future<List<StudyDocument>> listDocuments(int userId) async {
    final res = await _dio.get('/files/documents/$userId');
    final data = res.data as Map<String, dynamic>;
    return ((data['documents'] as List?) ?? [])
        .map((e) => StudyDocument.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDocument(int userId, String filename) async {
    await _dio.delete('/files/documents/$userId', queryParameters: {'filename': filename});
  }

  String _md(dynamic data) {
    final m = data as Map<String, dynamic>;
    if (m['error'] != null) throw Exception(m['error'].toString());
    return (m['markdown'] ?? '').toString();
  }
}

class StudyDocument {
  final String filename;
  final int chunks;
  final String topic;
  const StudyDocument({required this.filename, required this.chunks, required this.topic});
  factory StudyDocument.fromJson(Map<String, dynamic> j) => StudyDocument(
        filename: (j['filename'] ?? '').toString(),
        chunks: (j['chunks'] ?? 0) as int,
        topic: (j['topic'] ?? 'General').toString(),
      );
}

class PhotoKit {
  final String title;
  final String summary;
  final List<Flashcard> flashcards;
  final List<QuizQuestion> quiz;
  const PhotoKit({required this.title, required this.summary, required this.flashcards, required this.quiz});
  factory PhotoKit.fromJson(Map<String, dynamic> j) => PhotoKit(
        title: (j['title'] ?? '').toString(),
        summary: (j['summary'] ?? '').toString(),
        flashcards: ((j['flashcards'] as List?) ?? [])
            .map((e) => Flashcard.fromJson(e as Map<String, dynamic>)).toList(),
        quiz: ((j['quiz'] as List?) ?? [])
            .map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

class MapNode {
  final String id;
  final String label;
  final String group;
  const MapNode({required this.id, required this.label, required this.group});
  factory MapNode.fromJson(Map<String, dynamic> j) => MapNode(
        id: (j['id'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        group: (j['group'] ?? '').toString(),
      );
}

class MapEdge {
  final String from;
  final String to;
  final String label;
  const MapEdge({required this.from, required this.to, required this.label});
  factory MapEdge.fromJson(Map<String, dynamic> j) => MapEdge(
        from: (j['from'] ?? '').toString(),
        to: (j['to'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
      );
}

class KnowledgeMap {
  final List<MapNode> nodes;
  final List<MapEdge> edges;
  const KnowledgeMap({required this.nodes, required this.edges});
  factory KnowledgeMap.fromJson(Map<String, dynamic> j) => KnowledgeMap(
        nodes: ((j['nodes'] as List?) ?? []).map((e) => MapNode.fromJson(e as Map<String, dynamic>)).toList(),
        edges: ((j['edges'] as List?) ?? []).map((e) => MapEdge.fromJson(e as Map<String, dynamic>)).toList(),
      );
}

final studioRepositoryProvider =
    Provider<StudioRepository>((ref) => StudioRepository(ref.watch(dioProvider)));
