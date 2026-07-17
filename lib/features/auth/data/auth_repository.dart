import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
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
    final res = await _dio.post('/auth/password-reset/request', data: req.toJson());
    return (res.data as Map<String, dynamic>)['message'] as String;
  }

  Future<AuthResponse> confirmPasswordReset(PasswordResetConfirmRequest req) async {
    final res = await _dio.post('/auth/password-reset/confirm', data: req.toJson());
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

  Future<GoogleLoginUrlResponse> getGoogleLoginUrl(String redirectUri) async {
    final res = await _dio.get('/auth/google-login', queryParameters: {'redirect_uri': redirectUri});
    return GoogleLoginUrlResponse.fromJson(res.data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(dioProvider)));
