import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../auth/application/auth_controller.dart';
import 'subscription_models.dart';

class SubscriptionRepository {
  final Dio _dio;
  const SubscriptionRepository(this._dio);

  Future<SubscriptionStatus> getStatus(int userId) async {
    final res = await _dio.get('/payments/status/$userId');
    return SubscriptionStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<CheckoutResponse> checkout({required int userId, required String gateway}) async {
    final res = await _dio.post('/payments/checkout', data: {'user_id': userId, 'plan': 'premium', 'gateway': gateway});
    return CheckoutResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<bool> confirmPayment({required String sessionId, required int userId}) async {
    final res = await _dio.post('/payments/confirm', queryParameters: {'session_id': sessionId, 'user_id': userId}, data: {
      'session_id': sessionId,
      'user_id': userId,
    });
    return (res.data as Map<String, dynamic>)['ok'] as bool? ?? false;
  }
}

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) => SubscriptionRepository(ref.watch(dioProvider)));

/// Live subscription/premium status for the current user -- used by
/// PremiumGate and dashboard badges. Refetches whenever the auth session
/// (userId) changes. Fails silently to 'free' tier on any API error,
/// mirroring ilm-ai-mobile's SubscriptionContext.
final subscriptionStatusProvider = FutureProvider<SubscriptionStatus>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return SubscriptionStatus.free();
  try {
    return await ref.read(subscriptionRepositoryProvider).getStatus(userId);
  } catch (_) {
    return SubscriptionStatus.free();
  }
});
