import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../storage/secure_token_storage.dart';
import '../config/phone_qa.dart';
import '../config/integrated_beta.dart';
import 'mobile_api.dart';

const _defaultBaseUrl = 'https://ilm-ai-backend-256x.onrender.com';
final String apiBaseUrl = normalizeApiBaseUrl(
  const String.fromEnvironment('API_URL', defaultValue: _defaultBaseUrl),
);

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);
final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  final storage = SecureTokenStorage(ref.watch(secureStorageProvider));
  ref.onDispose(storage.dispose);
  return storage;
});

BaseOptions apiOptions({
  Duration receiveTimeout = const Duration(seconds: 60),
}) => BaseOptions(
  baseUrl: apiBaseUrl,
  connectTimeout: const Duration(seconds: 20),
  sendTimeout: const Duration(seconds: 30),
  receiveTimeout: receiveTimeout,
  // API redirects must not forward bearer tokens or credential request bodies.
  // OAuth navigation uses the separate, validated browser flow.
  followRedirects: false,
);

/// A queued refresh with storage compare-and-swap. Transient failures preserve
/// the session; retries can never cross an account/logout boundary.
class AuthInterceptor extends QueuedInterceptor {
  final Dio _plainDio;
  final SecureTokenStorage _tokenStorage;
  AuthInterceptor(this._tokenStorage, {Dio? transport})
    : _plainDio =
          transport ??
          Dio(apiOptions(receiveTimeout: const Duration(seconds: 20)));

  void dispose() => _plainDio.close(force: true);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final apiOrigin = Uri.parse(apiBaseUrl);
    final target = options.uri;
    if (target.userInfo.isNotEmpty ||
        target.scheme != apiOrigin.scheme ||
        target.host != apiOrigin.host ||
        target.port != apiOrigin.port) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError(
            'API requests must remain on the configured API origin.',
          ),
        ),
      );
      return;
    }
    // Enforce this even when a caller overrides BaseOptions or skips bearer
    // injection: logout/exchange bodies may themselves contain credentials.
    options.followRedirects = false;
    if (integratedBetaRequested &&
        (!integratedBeta || !isBetaOrigin(options.uri))) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError(
            'Beta requests must remain on the isolated beta API origin.',
          ),
        ),
      );
      return;
    }
    if (phoneQaRequested &&
        (!phoneQaEnabled || !isPhoneQaRequest(options.uri))) {
      handler.reject(
        DioException(
          requestOptions: options,
          error: StateError('Phone QA permits only the USB loopback API.'),
        ),
      );
      return;
    }
    try {
      if (options.extra['skipAuth'] != true) {
        final tokens = await _tokenStorage.getTokens();
        if (tokens != null) {
          options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
          options.extra['sessionUser'] = tokens.userId;
        }
      }
      handler.next(options);
    } catch (error, stack) {
      handler.reject(
        DioException(requestOptions: options, error: error, stackTrace: stack),
      );
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    try {
      await _handleError(err, handler);
    } catch (_) {
      // Storage failures and malformed refresh responses must also settle Dio.
      handler.next(err);
    }
  }

  Future<void> _handleError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401 ||
        err.requestOptions.extra['_retried'] == true ||
        err.requestOptions.extra['skipAuth'] == true ||
        err.requestOptions.extra['skipAuthRefresh'] == true) {
      handler.next(err);
      return;
    }
    final tokens = await _tokenStorage.getTokens();
    if (tokens == null ||
        (err.requestOptions.extra['sessionUser'] != null &&
            err.requestOptions.extra['sessionUser'] != tokens.userId)) {
      handler.next(err);
      return;
    }
    if (err.requestOptions.headers['Authorization'] ==
        'Bearer ${tokens.accessToken}') {
      late Response response;
      try {
        response = await _plainDio.post(
          '/auth/refresh',
          data: {'refresh_token': tokens.refreshToken},
        );
      } on DioException catch (error) {
        if (error.response?.statusCode == 401) {
          await _tokenStorage.clearTokens(expectedRefresh: tokens.refreshToken);
        }
        handler.reject(error);
        return;
      } catch (_) {
        handler.next(err);
        return;
      }
      final data = response.data;
      final access = data is Map ? data['access_token'] : null;
      final refresh = data is Map ? data['refresh_token'] : null;
      if (access is! String ||
          refresh is! String ||
          access.isEmpty ||
          refresh.isEmpty) {
        handler.next(err);
        return;
      }
      final installed = await _tokenStorage.replaceRefresh(
        tokens.refreshToken,
        access,
        refresh,
      );
      if (!installed) {
        // Logout raced the refresh: revoke the unused replacement remotely too.
        try {
          await _plainDio.post(
            '/auth/logout',
            data: {'refresh_token': refresh},
          );
        } catch (_) {}
        handler.next(err);
        return;
      }
    }
    final current = await _tokenStorage.getTokens();
    if (current == null || current.userId != tokens.userId) {
      handler.next(err);
      return;
    }
    final retry = err.requestOptions;
    retry.extra['_retried'] = true;
    retry.headers['Authorization'] = 'Bearer ${current.accessToken}';
    try {
      handler.resolve(await _plainDio.fetch(retry));
    } on DioException catch (error) {
      // A 500/offline response from the original endpoint is not an auth failure.
      handler.reject(error);
    } catch (_) {
      handler.next(err);
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(apiOptions());
  dio.interceptors.add(MobileApiInterceptor());
  final interceptor = AuthInterceptor(ref.watch(secureTokenStorageProvider));
  dio.interceptors.add(interceptor);
  ref.onDispose(interceptor.dispose);
  ref.onDispose(() => dio.close());
  return dio;
});
