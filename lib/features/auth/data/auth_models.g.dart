// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginRequestImpl _$$LoginRequestImplFromJson(Map<String, dynamic> json) =>
    _$LoginRequestImpl(
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$LoginRequestImplToJson(_$LoginRequestImpl instance) =>
    <String, dynamic>{'email': instance.email, 'password': instance.password};

_$AuthResponseImpl _$$AuthResponseImplFromJson(Map<String, dynamic> json) =>
    _$AuthResponseImpl(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$$AuthResponseImplToJson(_$AuthResponseImpl instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'refresh_token': instance.refreshToken,
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
    };

_$SignUpRequestImpl _$$SignUpRequestImplFromJson(Map<String, dynamic> json) =>
    _$SignUpRequestImpl(
      name: json['name'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );

Map<String, dynamic> _$$SignUpRequestImplToJson(_$SignUpRequestImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'password': instance.password,
    };

_$SignUpResponseImpl _$$SignUpResponseImplFromJson(Map<String, dynamic> json) =>
    _$SignUpResponseImpl(
      message: json['message'] as String,
      verificationRequired: json['verification_required'] as bool,
      email: json['email'] as String,
    );

Map<String, dynamic> _$$SignUpResponseImplToJson(
  _$SignUpResponseImpl instance,
) => <String, dynamic>{
  'message': instance.message,
  'verification_required': instance.verificationRequired,
  'email': instance.email,
};

_$VerifyEmailRequestImpl _$$VerifyEmailRequestImplFromJson(
  Map<String, dynamic> json,
) => _$VerifyEmailRequestImpl(
  email: json['email'] as String,
  code: json['code'] as String,
);

Map<String, dynamic> _$$VerifyEmailRequestImplToJson(
  _$VerifyEmailRequestImpl instance,
) => <String, dynamic>{'email': instance.email, 'code': instance.code};

_$ResendCodeRequestImpl _$$ResendCodeRequestImplFromJson(
  Map<String, dynamic> json,
) => _$ResendCodeRequestImpl(
  email: json['email'] as String,
  purpose: json['purpose'] as String,
);

Map<String, dynamic> _$$ResendCodeRequestImplToJson(
  _$ResendCodeRequestImpl instance,
) => <String, dynamic>{'email': instance.email, 'purpose': instance.purpose};

_$PasswordResetRequestBodyImpl _$$PasswordResetRequestBodyImplFromJson(
  Map<String, dynamic> json,
) => _$PasswordResetRequestBodyImpl(email: json['email'] as String);

Map<String, dynamic> _$$PasswordResetRequestBodyImplToJson(
  _$PasswordResetRequestBodyImpl instance,
) => <String, dynamic>{'email': instance.email};

_$PasswordResetConfirmRequestImpl _$$PasswordResetConfirmRequestImplFromJson(
  Map<String, dynamic> json,
) => _$PasswordResetConfirmRequestImpl(
  email: json['email'] as String,
  code: json['code'] as String,
  newPassword: json['new_password'] as String,
);

Map<String, dynamic> _$$PasswordResetConfirmRequestImplToJson(
  _$PasswordResetConfirmRequestImpl instance,
) => <String, dynamic>{
  'email': instance.email,
  'code': instance.code,
  'new_password': instance.newPassword,
};

_$RefreshResponseImpl _$$RefreshResponseImplFromJson(
  Map<String, dynamic> json,
) => _$RefreshResponseImpl(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
);

Map<String, dynamic> _$$RefreshResponseImplToJson(
  _$RefreshResponseImpl instance,
) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
};

_$UserProfileImpl _$$UserProfileImplFromJson(Map<String, dynamic> json) =>
    _$UserProfileImpl(
      userId: (json['user_id'] as num).toInt(),
      name: json['name'] as String,
      email: json['email'] as String,
      learningGoal: json['learning_goal'] as String?,
      targetDate: json['target_date'] as String?,
      profilePicture: json['profile_picture'] as String?,
      oauthProvider: json['oauth_provider'] as String?,
    );

Map<String, dynamic> _$$UserProfileImplToJson(_$UserProfileImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'name': instance.name,
      'email': instance.email,
      'learning_goal': instance.learningGoal,
      'target_date': instance.targetDate,
      'profile_picture': instance.profilePicture,
      'oauth_provider': instance.oauthProvider,
    };

_$UpdateProfileRequestImpl _$$UpdateProfileRequestImplFromJson(
  Map<String, dynamic> json,
) => _$UpdateProfileRequestImpl(
  userId: (json['user_id'] as num).toInt(),
  learningGoal: json['learning_goal'] as String?,
  targetDate: json['target_date'] as String?,
  name: json['name'] as String?,
  avatar: json['avatar'] as String?,
);

Map<String, dynamic> _$$UpdateProfileRequestImplToJson(
  _$UpdateProfileRequestImpl instance,
) => <String, dynamic>{
  'user_id': instance.userId,
  'learning_goal': instance.learningGoal,
  'target_date': instance.targetDate,
  'name': instance.name,
  'avatar': instance.avatar,
};

_$GoogleLoginUrlResponseImpl _$$GoogleLoginUrlResponseImplFromJson(
  Map<String, dynamic> json,
) => _$GoogleLoginUrlResponseImpl(
  authUrl: json['auth_url'] as String,
  state: json['state'] as String,
);

Map<String, dynamic> _$$GoogleLoginUrlResponseImplToJson(
  _$GoogleLoginUrlResponseImpl instance,
) => <String, dynamic>{'auth_url': instance.authUrl, 'state': instance.state};
