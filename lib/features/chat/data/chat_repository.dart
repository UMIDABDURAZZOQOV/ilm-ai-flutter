import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'chat_models.dart';

class ChatRepository {
  final Dio _dio;
  const ChatRepository(this._dio);

  Future<ChatAskResponse> ask({required int userId, required String question, required String language}) async {
    final res = await _dio.post('/chat/ask', data: {'user_id': userId, 'question': question, 'language': language});
    return ChatAskResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getHistory(int userId) async {
    final res = await _dio.get('/chat/history/$userId');
    final data = res.data as Map<String, dynamic>;
    return (data['history'] as List? ?? []).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> clearHistory(int userId) => _dio.delete('/chat/history/$userId');
}

final chatRepositoryProvider = Provider<ChatRepository>((ref) => ChatRepository(ref.watch(dioProvider)));
