import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

/// Holds the current session (null = logged out). AsyncValue so the router
/// can distinguish "still restoring from secure storage" (loading) from
/// "confirmed logged out" (data: null) and avoid a flash-of-wrong-route on
/// cold start.
class AuthController extends AsyncNotifier<StoredTokens?> {
  StreamSubscription<void>? _authClearedSub;
  bool _pushRegistered = false;

  @override
  Future<StoredTokens?> build() async {
    _authClearedSub ??= onAuthCleared.listen((_) {
      state = const AsyncData(null);
    });
    ref.onDispose(() => _authClearedSub?.cancel());
    final tokens = await ref.read(secureTokenStorageProvider).getTokens();
    if (tokens != null) _registerPushOnce(tokens.userId);
    return tokens;
  }

  /// One-shot per app session, mirroring ilm-ai-mobile's useRef guard around
  /// registerForPushNotifications() in RootNavigator.
  void _registerPushOnce(int userId) {
    if (_pushRegistered) return;
    _pushRegistered = true;
    PushService.registerWithBackend(ref, userId);
  }

  Future<void> login(AuthResponse res) async {
    final tokens = StoredTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
      userId: res.userId,
      name: res.name,
      email: res.email,
    );
    await ref.read(secureTokenStorageProvider).saveTokens(tokens);
    state = AsyncData(tokens);
    _registerPushOnce(tokens.userId);
  }

  Future<void> logout() async {
    final tokens = state.valueOrNull;
    if (tokens != null) {
      try {
        await ref.read(authRepositoryProvider).logout(tokens.refreshToken);
      } catch (_) {
        // best-effort server-side logout, always clear local state regardless
      }
    }
    await ref.read(secureTokenStorageProvider).clearTokens();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, StoredTokens?>(AuthController.new);

/// Convenience accessor used throughout the app wherever a screen needs the
/// logged-in user's id for an API call.
final currentUserIdProvider = Provider<int?>((ref) => ref.watch(authControllerProvider).valueOrNull?.userId);

