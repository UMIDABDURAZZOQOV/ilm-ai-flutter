import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/api_contract.dart';
import 'auth_models.dart';

/// Ported 1:1 from ilm-ai-mobile's src/api/auth.ts.
class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  Future<AuthResponse> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<SignUpResponse> signUp(SignUpRequest req) async {
    final res = await _dio.post('/auth/signup', data: req.toJson());
    return SignUpResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<AuthResponse> verifyEmail(VerifyEmailRequest req) async {
    final res = await _dio.post('/auth/verify-email', data: req.toJson());
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> resendCode(ResendCodeRequest req) async {
    final res = await _dio.post('/auth/resend-code', data: req.toJson());
    return (res.data as Map<String, dynamic>)['message'] as String;
  }

  Future<String> requestPasswordReset(PasswordResetRequestBody req) async {
    final res = await _dio.post(
      '/auth/password-reset/request',
      data: req.toJson(),
    );
    return (res.data as Map<String, dynamic>)['message'] as String;
  }

  Future<AuthResponse> confirmPasswordReset(
    PasswordResetConfirmRequest req,
  ) async {
    final res = await _dio.post(
      '/auth/password-reset/confirm',
      data: req.toJson(),
    );
    return AuthResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> logout(String refreshToken) async {
    await _dio.post('/auth/logout', data: {'refresh_token': refreshToken});
  }

  Future<UserProfile> getProfile(int userId) async {
    final res = await _dio.get('/auth/profile/$userId');
    return UserProfile.fromJson(res.data as Map<String, dynamic>);
  }

  Future<String> updateProfile(UpdateProfileRequest req) async {
    final res = await _dio.post('/auth/update-profile', data: req.toJson());
    return (res.data as Map<String, dynamic>)['message'] as String;
  }

  /// Saves the name + age the user picks right after Google sign-in (both required).
  Future<void> completeOnboarding({
    required int userId,
    required String name,
    required int age,
  }) async {
    await _dio.post(
      '/auth/complete-onboarding',
      data: {'user_id': userId, 'name': name, 'age': age},
    );
  }

  Future<Map<String, dynamic>> exchangeMobileCode(
    String code,
    String verifier,
  ) async {
    final response = await _dio.post(
      '/auth/mobile/exchange',
      data: {'code': code, 'code_verifier': verifier},
      options: Options(extra: {'skipAuth': true}),
    );
    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<bool> needsOnboarding(int userId) async {
    final response = await _dio.get('/auth/profile/$userId');
    final value = response.data['needs_onboarding'];
    if (value is! bool) throw const FormatException('Invalid profile state');
    return value;
  }

  Future<GoogleLoginUrlResponse> getGoogleLoginUrl(
    String redirectUri, {
    String? challenge,
  }) async {
    final res = await _dio.get(
      '/auth/google-login',
      queryParameters: {
        'redirect_uri': redirectUri,
        'code_challenge': ?challenge,
        if (challenge != null) 'code_challenge_method': 'S256',
      },
      options: Options(extra: {'skipAuth': true}),
    );
    if (res.data is! Map<String, dynamic>) {
      throw const InvalidApiResponseException();
    }
    final data = res.data as Map<String, dynamic>;
    // Fail before opening an old callback that puts JWTs in a custom URI.
    if (challenge != null && data['mobile_auth_version'] != 2) {
      throw const ApiCompatibilityException();
    }
    final rawUrl = data['auth_url'];
    final authUri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (authUri == null ||
        authUri.scheme != 'https' ||
        authUri.host != 'accounts.google.com' ||
        authUri.userInfo.isNotEmpty ||
        data['state'] is! String ||
        (data['state'] as String).isEmpty) {
      throw const InvalidApiResponseException();
    }
    return GoogleLoginUrlResponse.fromJson(data);
  }

  Future<GoogleLoginUrlResponse> prepareGoogleLogin(String challenge) async {
    late Response response;
    try {
      response = await _dio.get(
        '/auth/mobile/config',
        options: Options(extra: {'skipAuth': true}),
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        throw const ApiCompatibilityException();
      }
      rethrow;
    }
    final config = response.data;
    if (config is! Map ||
        config['mobile_auth_version'] != 2 ||
        config['pkce_method'] != 'S256' ||
        config['code_exchange_path'] != '/auth/mobile/exchange') {
      throw const ApiCompatibilityException();
    }
    if (config['google_configured'] != true) {
      throw const GoogleAuthException(GoogleAuthFailure.notConfigured);
    }
    final redirect =
        config['redirect_uri'] ?? '$apiBaseUrl/auth/google-callback-mobile';
    final uri = redirect is String ? Uri.tryParse(redirect) : null;
    if (uri == null ||
        !uri.hasAuthority ||
        uri.path != '/auth/google-callback-mobile' ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                {'localhost', '127.0.0.1', '::1'}.contains(uri.host)))) {
      throw const InvalidApiResponseException();
    }
    return getGoogleLoginUrl(redirect as String, challenge: challenge);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(dioProvider)),
);
