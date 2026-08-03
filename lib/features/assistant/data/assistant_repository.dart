import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../chat/data/chat_models.dart';

/// A suggested in-app action the companion can offer (e.g. "Open a quiz").
class AssistantAction {
  final String label;
  final String href;
  const AssistantAction({required this.label, required this.href});
  static AssistantAction? fromJson(dynamic j) {
    if (j is! Map) return null;
    final href = (j['href'] ?? '').toString();
    final label = (j['label'] ?? '').toString();
    if (href.isEmpty || label.isEmpty) return null;
    return AssistantAction(label: label, href: href);
  }
}

/// The companion's full reply: the answer plus its RAG sources, an optional
/// action button, and up to three follow-up question suggestions.
class AssistantAnswer {
  final String answer;
  final AssistantAction? action;
  final List<String> sources;
  final List<String> followups;
  const AssistantAnswer({required this.answer, this.action, this.sources = const [], this.followups = const []});
  factory AssistantAnswer.fromJson(Map<String, dynamic> j) => AssistantAnswer(
        answer: (j['answer'] ?? '').toString(),
        action: AssistantAction.fromJson(j['action']),
        sources: ((j['sources'] as List?) ?? []).map((e) => e.toString()).toList(),
        followups: ((j['followups'] as List?) ?? []).map((e) => e.toString()).toList(),
      );
}

class AssistantRepository {
  final Dio _dio;
  const AssistantRepository(this._dio);

  Future<AssistantAnswer> ask({required int userId, required String question, required String language}) async {
    final res = await _dio.post('/assistant/ask', data: {'user_id': userId, 'question': question, 'language': language});
    return AssistantAnswer.fromJson(res.data as Map<String, dynamic>);
  }

  /// Multimodal chat: attach a photo (a problem, notes, a diagram) with an
  /// optional question. Returns the answer plus action/follow-ups (no sources).
  Future<AssistantAnswer> askImage({required int userId, required String question, required String language, required String imagePath}) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'question': question,
      'language': language,
      'image': await MultipartFile.fromFile(imagePath),
    });
    final res = await _dio.post('/assistant/ask-image', data: formData);
    return AssistantAnswer.fromJson(res.data as Map<String, dynamic>);
  }

  /// Uploads a recorded audio clip; Gemini transcribes and answers in one
  /// multimodal call. Returns the answer text (no transcription is returned).
  Future<String> askVoice({required int userId, required String language, required String audioPath}) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'language': language,
      'audio': await MultipartFile.fromFile(audioPath, filename: 'voice.m4a'),
    });
    final res = await _dio.post('/assistant/ask-voice', data: formData);
    return (res.data as Map<String, dynamic>)['answer'] as String? ?? '';
  }

  /// Synthesizes speech via the backend's ElevenLabs-backed /speak endpoint.
  /// Returns raw base64-encoded audio bytes (caller writes to a temp file).
  /// Throws on any failure -- callers should fall back to on-device TTS.
  Future<String> speak({required String text, required String language}) async {
    final res = await _dio.post(
      '/assistant/speak',
      data: {'text': text, 'language': language},
      options: Options(sendTimeout: const Duration(seconds: 60), receiveTimeout: const Duration(seconds: 60)),
    );
    return (res.data as Map<String, dynamic>)['audio_base64'] as String;
  }

  Future<List<ChatMessage>> getHistory(int userId) async {
    final res = await _dio.get('/assistant/history/$userId');
    final data = res.data as Map<String, dynamic>;
    return (data['history'] as List? ?? []).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearHistory(int userId) => _dio.delete('/assistant/history/$userId');
}

final assistantRepositoryProvider = Provider<AssistantRepository>((ref) => AssistantRepository(ref.watch(dioProvider)));
