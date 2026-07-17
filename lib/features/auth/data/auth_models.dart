// ignore_for_file: invalid_annotation_target -- known freezed+json_serializable
// interaction when @JsonKey is applied directly to constructor params; the
// generated code is correct, this only suppresses a cosmetic analyzer warning.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// Request/response DTOs for /auth/*, ported from ilm-ai-mobile's
/// src/api/auth.ts + src/types/api.ts.

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({required String email, required String password}) = _LoginRequest;
  factory LoginRequest.fromJson(Map<String, dynamic> json) => _$LoginRequestFromJson(json);
}

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
    @JsonKey(name: 'user_id') required int userId,
    required String name,
    required String email,
  }) = _AuthResponse;
  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
}

@freezed
class SignUpRequest with _$SignUpRequest {
  const factory SignUpRequest({required String name, required String email, required String password}) = _SignUpRequest;
  factory SignUpRequest.fromJson(Map<String, dynamic> json) => _$SignUpRequestFromJson(json);
}

@freezed
class SignUpResponse with _$SignUpResponse {
  const factory SignUpResponse({
    required String message,
    @JsonKey(name: 'verification_required') required bool verificationRequired,
    required String email,
  }) = _SignUpResponse;
  factory SignUpResponse.fromJson(Map<String, dynamic> json) => _$SignUpResponseFromJson(json);
}

@freezed
class VerifyEmailRequest with _$VerifyEmailRequest {
  const factory VerifyEmailRequest({required String email, required String code}) = _VerifyEmailRequest;
  factory VerifyEmailRequest.fromJson(Map<String, dynamic> json) => _$VerifyEmailRequestFromJson(json);
}

@freezed
class ResendCodeRequest with _$ResendCodeRequest {
  const factory ResendCodeRequest({required String email, required String purpose}) = _ResendCodeRequest;
  factory ResendCodeRequest.fromJson(Map<String, dynamic> json) => _$ResendCodeRequestFromJson(json);
}

@freezed
class PasswordResetRequestBody with _$PasswordResetRequestBody {
  const factory PasswordResetRequestBody({required String email}) = _PasswordResetRequestBody;
  factory PasswordResetRequestBody.fromJson(Map<String, dynamic> json) => _$PasswordResetRequestBodyFromJson(json);
}

@freezed
class PasswordResetConfirmRequest with _$PasswordResetConfirmRequest {
  const factory PasswordResetConfirmRequest({
    required String email,
    required String code,
    @JsonKey(name: 'new_password') required String newPassword,
  }) = _PasswordResetConfirmRequest;
  factory PasswordResetConfirmRequest.fromJson(Map<String, dynamic> json) => _$PasswordResetConfirmRequestFromJson(json);
}

@freezed
class RefreshResponse with _$RefreshResponse {
  const factory RefreshResponse({
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _RefreshResponse;
  factory RefreshResponse.fromJson(Map<String, dynamic> json) => _$RefreshResponseFromJson(json);
}

@freezed
class UserProfile with _$UserProfile {
  const factory UserProfile({
    @JsonKey(name: 'user_id') required int userId,
    required String name,
    required String email,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    @JsonKey(name: 'profile_picture') String? profilePicture,
    @JsonKey(name: 'oauth_provider') String? oauthProvider,
  }) = _UserProfile;
  factory UserProfile.fromJson(Map<String, dynamic> json) => _$UserProfileFromJson(json);
}

@freezed
class UpdateProfileRequest with _$UpdateProfileRequest {
  const factory UpdateProfileRequest({
    @JsonKey(name: 'user_id') required int userId,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    String? name,
    String? avatar,
  }) = _UpdateProfileRequest;
  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateProfileRequestFromJson(json);
}

@freezed
class GoogleLoginUrlResponse with _$GoogleLoginUrlResponse {
  const factory GoogleLoginUrlResponse({
    @JsonKey(name: 'auth_url') required String authUrl,
    required String state,
  }) = _GoogleLoginUrlResponse;
  factory GoogleLoginUrlResponse.fromJson(Map<String, dynamic> json) => _$GoogleLoginUrlResponseFromJson(json);
}
