import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class FeedbackRepository {
  final Dio _dio;
  const FeedbackRepository(this._dio);

  Future<void> submit({required String name, required String email, required String message, required int rating}) async {
    await _dio.post('/feedback/submit', data: {'name': name, 'email': email, 'message': message, 'rating': rating});
  }
}

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) => FeedbackRepository(ref.watch(dioProvider)));
