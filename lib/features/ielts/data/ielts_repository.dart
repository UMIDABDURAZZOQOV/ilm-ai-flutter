import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'ielts_models.dart';

class IeltsRepository {
  final Dio _dio;
  const IeltsRepository(this._dio);

  /// Audio/image URLs from the API may be relative (e.g. "/static/..."); make
  /// them absolute so just_audio / Image.network can load them.
  static String resolveUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = apiBaseUrl.endsWith('/') ? apiBaseUrl.substring(0, apiBaseUrl.length - 1) : apiBaseUrl;
    return url.startsWith('/') ? '$base$url' : '$base/$url';
  }

  // ── Listening ──
  Future<List<IeltsListening>> listListening({int? section, String? difficulty}) async {
    final res = await _dio.get('/ielts/listening', queryParameters: {
      'section': ?section,
      'difficulty': ?difficulty,
    });
    return (res.data as List).map((e) => IeltsListening.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<IeltsQuestion>> listeningQuestions(int id) => _questions('/ielts/listening/$id/questions');

  // ── Reading ──
  Future<List<IeltsReading>> listReading({int? section, String? difficulty}) async {
    final res = await _dio.get('/ielts/reading', queryParameters: {
      'section': ?section,
      'difficulty': ?difficulty,
    });
    return (res.data as List).map((e) => IeltsReading.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<IeltsQuestion>> readingQuestions(int id) => _questions('/ielts/reading/$id/questions');

  // ── Writing ──
  Future<List<IeltsWriting>> listWriting({String? taskType, String? difficulty}) async {
    final res = await _dio.get('/ielts/writing', queryParameters: {
      'task_type': ?taskType,
      'difficulty': ?difficulty,
    });
    return (res.data as List).map((e) => IeltsWriting.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<IeltsWritingSubmission> submitWriting({required int userId, required int taskId, required String essay}) async {
    final res = await _dio.post('/ielts/writing/submit', data: {
      'user_id': userId,
      'task_id': taskId,
      'essay_text': essay,
    });
    return IeltsWritingSubmission.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Speaking ──
  Future<List<IeltsSpeaking>> listSpeaking({int? part, String? difficulty}) async {
    final res = await _dio.get('/ielts/speaking', queryParameters: {
      'part': ?part,
      'difficulty': ?difficulty,
    });
    return (res.data as List).map((e) => IeltsSpeaking.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<IeltsSpeakingSubmission> submitSpeaking({
    required int userId,
    required int topicId,
    required String audioBase64,
    String mimeType = 'audio/mp4',
    int? durationSeconds,
  }) async {
    final res = await _dio.post('/ielts/speaking/submit', data: {
      'user_id': userId,
      'topic_id': topicId,
      'audio_base64': audioBase64,
      'mime_type': mimeType,
      'duration_seconds': ?durationSeconds,
    }, options: Options(sendTimeout: const Duration(seconds: 90), receiveTimeout: const Duration(seconds: 90)));
    return IeltsSpeakingSubmission.fromJson(res.data as Map<String, dynamic>);
  }

  // ── Mock test ──
  Future<IeltsMockTest> startMock({required int userId, required String testType}) async {
    final res = await _dio.post('/ielts/mock-test/start', data: {'user_id': userId, 'test_type': testType});
    return IeltsMockTest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<IeltsMockTest> completeMock(int testId) async {
    final res = await _dio.post('/ielts/mock-test/$testId/complete');
    return IeltsMockTest.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<IeltsMockTest>> userMocks(int userId) async {
    final res = await _dio.get('/ielts/mock-test/user/$userId');
    return (res.data as List).map((e) => IeltsMockTest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<IeltsQuestion>> _questions(String path) async {
    final res = await _dio.get(path);
    return (res.data as List).map((e) => IeltsQuestion.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
}

final ieltsRepositoryProvider = Provider<IeltsRepository>((ref) => IeltsRepository(ref.watch(dioProvider)));
