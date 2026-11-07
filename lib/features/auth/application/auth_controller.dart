import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/notifications/push_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../../onboarding/data/onboarding_draft.dart';
import '../../skills/application/learning_preferences.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final needsProfileSetupProvider = StateProvider<bool>((ref) => false);
final sessionRestoreErrorProvider = StateProvider<Object?>((ref) => null);

/// Secure storage is the session authority, including refreshes and profile edits.
class AuthController extends AsyncNotifier<StoredTokens?> {
  StreamSubscription<StoredTokens?>? _changes;
  Future<void>? _resuming;
  int? _resumingUser, _syncedUser;
  DateTime? _lastSync;
  int _epoch = 0;
  DateTime get now => DateTime.now();

  @override
  Future<StoredTokens?> build() async {
    final epoch = ++_epoch;
    final storage = ref.read(secureTokenStorageProvider);
    _changes = storage.changes.listen((tokens) {
      state = AsyncData(tokens);
      if (tokens == null) {
        ref.read(needsProfileSetupProvider.notifier).state = false;
        PushService.stop();
      } else if (tokens.needsOnboarding != null) {
        ref.read(needsProfileSetupProvider.notifier).state =
            tokens.needsOnboarding!;
      }
    });
    ref.onDispose(() {
      _epoch++;
      _changes?.cancel();
      PushService.stop();
    });
    final tokens = await storage.getTokens();
    if (tokens == null) return null;
    ref.read(onboardingCompleteProvider.notifier).complete();
    if (tokens.needsOnboarding != null) {
      ref.read(needsProfileSetupProvider.notifier).state =
          tokens.needsOnboarding!;
      // Cached routing is immediate. Every protected request still authenticates
      // on the server; a confirmed failed refresh clears secure storage as before.
      unawaited(_trackRestore(storage, tokens, epoch));
      return tokens;
    }
    // Legacy sessions without a known profile state must resolve it or show the
    // existing retry screen, rather than silently skipping required onboarding.
    await _trackRestore(storage, tokens, epoch);
    return storage.getTokens();
  }

  Future<void> _trackRestore(
    SecureTokenStorage storage,
    StoredTokens tokens,
    int epoch,
  ) {
    final generation = storage.sessionGeneration;
    _resumingUser = tokens.userId;
    final task = _restoreSession(storage, tokens, epoch, generation);
    _resuming = task;
    return task.whenComplete(() {
      if (identical(_resuming, task)) {
        _resuming = null;
        _resumingUser = null;
      }
    });
  }

  Future<void> _restoreSession(
    SecureTokenStorage storage,
    StoredTokens tokens,
    int epoch,
    int generation,
  ) async {
    bool currentSession() =>
        _epoch == epoch && storage.sessionGeneration == generation;
    try {
      final restored = await Future.wait<dynamic>([
        ref.read(authRepositoryProvider).needsOnboarding(tokens.userId),
        ref.read(learningPreferencesProvider).restore(tokens.userId),
      ], eagerError: true);
      if (!currentSession()) return;
      final pending = restored[0] as bool;
      final updated = await storage.updateTokens(
        (current) => currentSession() && current.userId == tokens.userId
            ? current.copyWith(needsOnboarding: pending)
            : current,
      );
      if (!currentSession() || updated?.userId != tokens.userId) return;
      ref.read(needsProfileSetupProvider.notifier).state = pending;
      ref.read(sessionRestoreErrorProvider.notifier).state = null;
      _syncedUser = tokens.userId;
      _lastSync = now;
      ref.read(studyRevisionProvider.notifier).state++;
      _registerPush(tokens.userId);
    } catch (error) {
      if (!currentSession()) return;
      final current = await storage.getTokens();
      if (!currentSession() || current == null) return;
      ref.read(needsProfileSetupProvider.notifier).state =
          current.needsOnboarding ?? true;
      if (current.needsOnboarding == null) {
        ref.read(sessionRestoreErrorProvider.notifier).state = error;
      }
      _registerPush(current.userId);
    }
  }

  Future<void> resume() {
    final tokens = state.valueOrNull;
    if (tokens == null) return Future.value();
    if (_resumingUser == tokens.userId && _resuming != null) return _resuming!;
    final dirty = ref
        .read(prefsServiceProvider)
        .getBool('study_preferences_dirty_${tokens.userId}');
    if (!dirty &&
        _syncedUser == tokens.userId &&
        _lastSync != null &&
        now.difference(_lastSync!) < const Duration(seconds: 30)) {
      return Future.value();
    }
    return _trackRestore(ref.read(secureTokenStorageProvider), tokens, _epoch);
  }

  Future<void> retryRestore() async {
    ref.read(sessionRestoreErrorProvider.notifier).state = null;
    ref.invalidateSelf();
    await future;
  }

  void _registerPush(int userId) {
    final dio = ref.read(dioProvider);
    PushService.registerWithBackend(
      dio,
      userId,
      () => state.valueOrNull?.userId == userId,
    );
  }

  Future<void> login(AuthResponse res, {bool needsOnboarding = false}) async {
    _epoch++;
    final storage = ref.read(secureTokenStorageProvider);
    final draftStore = OnboardingDraftStore(ref.read(prefsServiceProvider));
    final draft = await draftStore.adopt(res.userId);
    final tokens = StoredTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
      userId: res.userId,
      name: res.name,
      email: res.email,
      needsOnboarding: needsOnboarding,
    );
    ref.read(needsProfileSetupProvider.notifier).state = needsOnboarding;
    ref.read(sessionRestoreErrorProvider.notifier).state = null;
    await storage.saveTokens(tokens);
    state = AsyncData(tokens);
    if (needsOnboarding && draft?['completed'] == true) {
      final name = draft?['name'];
      final age = int.tryParse('${draft?['age']}');
      if (name is String &&
          name.trim().length >= 2 &&
          age != null &&
          age >= 5 &&
          age <= 100) {
        try {
          await ref
              .read(authRepositoryProvider)
              .completeOnboarding(
                userId: res.userId,
                name: name.trim(),
                age: age,
              );
          await markProfileComplete(name.trim(), userId: res.userId);
          await draftStore.clear(res.userId);
        } catch (_) {
          // The account draft remains available on setup for a visible retry.
        }
      }
    }
    await ref.read(learningPreferencesProvider).restore(res.userId);
    _syncedUser = res.userId;
    _lastSync = now;
    ref.read(studyRevisionProvider.notifier).state++;
    _registerPush(res.userId);
  }

  Future<void> markProfileComplete(String name, {int? userId}) async {
    final expected = userId ?? state.valueOrNull?.userId;
    final updated = await ref
        .read(secureTokenStorageProvider)
        .updateTokens(
          (current) => current.userId == expected
              ? current.copyWith(name: name, needsOnboarding: false)
              : current,
        );
    state = AsyncData(updated);
    ref.read(needsProfileSetupProvider.notifier).state =
        updated?.needsOnboarding ?? false;
  }

  Future<void> logout() async {
    _epoch++;
    _syncedUser = null;
    _lastSync = null;
    final storage = ref.read(secureTokenStorageProvider);
    final tokens = await storage.getTokens();
    final dio = ref.read(dioProvider);
    final pushToken = PushService.stop();
    await storage.clearTokens();
    state = const AsyncData(null);
    ref.read(needsProfileSetupProvider.notifier).state = false;
    // Local logout never waits for an unreachable server.
    if (tokens != null) {
      unawaited(_revoke(dio, tokens, pushToken));
    }
  }

  Future<void> _revoke(Dio dio, StoredTokens tokens, String? pushToken) async {
    final options = Options(
      headers: {'Authorization': 'Bearer ${tokens.accessToken}'},
      extra: {'skipAuth': true},
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
    if (pushToken != null) {
      await PushService.unregister(dio, tokens.userId, pushToken, options);
    }
    try {
      await dio.post(
        '/auth/logout',
        data: {'refresh_token': tokens.refreshToken},
        options: options,
      );
    } catch (_) {}
  }

  Future<void> updateDisplayName(String name) async {
    final userId = state.valueOrNull?.userId;
    if (userId == null) throw StateError('Not signed in');
    final trimmed = name.trim();
    if (trimmed.length < 2) throw ArgumentError('Name too short');
    await ref
        .read(authRepositoryProvider)
        .updateProfile(UpdateProfileRequest(userId: userId, name: trimmed));
    final updated = await ref
        .read(secureTokenStorageProvider)
        .updateTokens(
          (current) => current.userId == userId
              ? current.copyWith(name: trimmed)
              : current,
        );
    state = AsyncData(updated);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, StoredTokens?>(AuthController.new);
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authControllerProvider).valueOrNull?.userId,
);
