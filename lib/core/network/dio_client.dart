import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_token_storage.dart';

/// Base URL mirrors ilm-ai-mobile's EXPO_PUBLIC_API_URL build-time env var --
/// pass `--dart-define=API_URL=http://LAN_IP:8000` when running against a
/// physical device, same LAN setup already validated for the RN app.
const _defaultBaseUrl = 'http://localhost:8000';
const String apiBaseUrl = String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl);

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) => const FlutterSecureStorage());

final secureTokenStorageProvider = Provider<SecureTokenStorage>(
  (ref) => SecureTokenStorage(ref.watch(secureStorageProvider)),
);

/// Broadcasts when a refresh-token attempt fails, so AuthController can
/// reactively clear state and the router can kick the user back to /login --
/// mirrors ilm-ai-mobile's client.ts onAuthCleared/notifyAuthCleared pub/sub.
final _authClearedController = StreamController<void>.broadcast();
Stream<void> get onAuthCleared => _authClearedController.stream;
void _notifyAuthCleared() => _authClearedController.add(null);

/// Single-flight 401 handling: on the first 401, pause all subsequent
/// requests, do exactly one refresh call, then replay the queue. Ported from
/// ilm-ai-mobile's api/client.ts interceptor design, implemented here with
/// dio's QueuedInterceptor which provides the same "pause queue, do one
/// thing, resume queue" semantics natively.
class AuthInterceptor extends QueuedInterceptor {
  final Dio _plainDio;
  final SecureTokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage) : _plainDio = Dio(BaseOptions(baseUrl: apiBaseUrl));

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final tokens = await _tokenStorage.getTokens();
    if (tokens != null) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final alreadyRetried = err.requestOptions.extra['_retried'] == true;

    if (response?.statusCode != 401 || alreadyRetried) {
      handler.next(err);
      return;
    }

    final tokens = await _tokenStorage.getTokens();
    if (tokens == null) {
      handler.next(err);
      return;
    }

    // QueuedInterceptor serializes onError calls, but several requests can
    // still have failed concurrently with the same stale token before any of
    // them reached this point. If the token on disk has already moved on
    // from what this request was sent with, another queued call already did
    // the refresh -- just retry with the current token instead of hitting
    // /auth/refresh again.
    final failedAuthHeader = err.requestOptions.headers['Authorization'] as String?;
    if (failedAuthHeader != null && failedAuthHeader != 'Bearer ${tokens.accessToken}') {
      final retryOptions = err.requestOptions;
      retryOptions.extra['_retried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      try {
        final retryResponse = await Dio(BaseOptions(baseUrl: apiBaseUrl)).fetch(retryOptions);
        handler.resolve(retryResponse);
      } catch (_) {
        handler.next(err);
      }
      return;
    }

    try {
      final refreshResponse = await _plainDio.post('/auth/refresh', data: {'refresh_token': tokens.refreshToken});
      final newAccess = refreshResponse.data['access_token'] as String;
      final newRefresh = refreshResponse.data['refresh_token'] as String;
      await _tokenStorage.saveTokens(tokens.copyWith(accessToken: newAccess, refreshToken: newRefresh));

      final retryOptions = err.requestOptions;
      retryOptions.extra['_retried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer $newAccess';

      final retryDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
      final retryResponse = await retryDio.fetch(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await _tokenStorage.clearTokens();
      _notifyAuthCleared();
      handler.next(err);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(baseUrl: apiBaseUrl, connectTimeout: const Duration(seconds: 30)));
  dio.interceptors.add(AuthInterceptor(ref.watch(secureTokenStorageProvider)));
  return dio;
});
