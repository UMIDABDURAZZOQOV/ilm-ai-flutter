import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../chat/data/chat_models.dart';

class AssistantRepository {
  final Dio _dio;
  const AssistantRepository(this._dio);

  Future<String> ask({required int userId, required String question, required String language}) async {
    final res = await _dio.post('/assistant/ask', data: {'user_id': userId, 'question': question, 'language': language});
    return (res.data as Map<String, dynamic>)['answer'] as String? ?? '';
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
