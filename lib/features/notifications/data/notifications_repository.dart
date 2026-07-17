import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class NotificationsRepository {
  final Dio _dio;
  const NotificationsRepository(this._dio);

  Future<void> registerToken({required int userId, required String token}) async {
    await _dio.post('/notifications/register-token', data: {'user_id': userId, 'token': token});
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) => NotificationsRepository(ref.watch(dioProvider)));
