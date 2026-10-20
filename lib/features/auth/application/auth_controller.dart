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

  @override
  Future<StoredTokens?> build() async {
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
      _changes?.cancel();
      PushService.stop();
    });
    final tokens = await storage.getTokens();
    if (tokens == null) return null;
    ref.read(onboardingCompleteProvider.notifier).complete();
    try {
      final pending = await ref
          .read(authRepositoryProvider)
          .needsOnboarding(tokens.userId);
      final updated = await storage.updateTokens(
        (current) => current.userId == tokens.userId
            ? current.copyWith(needsOnboarding: pending)
            : current,
      );
      ref.read(needsProfileSetupProvider.notifier).state = pending;
      await ref.read(learningPreferencesProvider).restore(tokens.userId);
      ref.read(studyRevisionProvider.notifier).state++;
      _registerPush(tokens.userId);
      return updated;
    } catch (error) {
      final current = await storage.getTokens();
      if (current == null) {
        return null; // Only a confirmed refresh 401 clears it.
      }
      ref.read(needsProfileSetupProvider.notifier).state =
          current.needsOnboarding ?? true;
      if (current.needsOnboarding == null) {
        ref.read(sessionRestoreErrorProvider.notifier).state = error;
      }
      _registerPush(current.userId);
      return current;
    }
  }

  Future<void> resume() async {
    final userId = state.valueOrNull?.userId;
    if (userId == null) return;
    _registerPush(userId);
    await ref.read(learningPreferencesProvider).restore(userId);
    if (state.valueOrNull?.userId == userId) {
      ref.read(studyRevisionProvider.notifier).state++;
    }
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
