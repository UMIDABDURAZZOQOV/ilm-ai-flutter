// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) {
  return _LoginRequest.fromJson(json);
}

/// @nodoc
mixin _$LoginRequest {
  String get email => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;

  /// Serializes this LoginRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LoginRequestCopyWith<LoginRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LoginRequestCopyWith<$Res> {
  factory $LoginRequestCopyWith(
    LoginRequest value,
    $Res Function(LoginRequest) then,
  ) = _$LoginRequestCopyWithImpl<$Res, LoginRequest>;
  @useResult
  $Res call({String email, String password});
}

/// @nodoc
class _$LoginRequestCopyWithImpl<$Res, $Val extends LoginRequest>
    implements $LoginRequestCopyWith<$Res> {
  _$LoginRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? password = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$LoginRequestImplCopyWith<$Res>
    implements $LoginRequestCopyWith<$Res> {
  factory _$$LoginRequestImplCopyWith(
    _$LoginRequestImpl value,
    $Res Function(_$LoginRequestImpl) then,
  ) = __$$LoginRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, String password});
}

/// @nodoc
class __$$LoginRequestImplCopyWithImpl<$Res>
    extends _$LoginRequestCopyWithImpl<$Res, _$LoginRequestImpl>
    implements _$$LoginRequestImplCopyWith<$Res> {
  __$$LoginRequestImplCopyWithImpl(
    _$LoginRequestImpl _value,
    $Res Function(_$LoginRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? password = null}) {
    return _then(
      _$LoginRequestImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$LoginRequestImpl implements _LoginRequest {
  const _$LoginRequestImpl({required this.email, required this.password});

  factory _$LoginRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$LoginRequestImplFromJson(json);

  @override
  final String email;
  @override
  final String password;

  @override
  String toString() {
    return 'LoginRequest(email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginRequestImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, password);

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      __$$LoginRequestImplCopyWithImpl<_$LoginRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$LoginRequestImplToJson(this);
  }
}

abstract class _LoginRequest implements LoginRequest {
  const factory _LoginRequest({
    required final String email,
    required final String password,
  }) = _$LoginRequestImpl;

  factory _LoginRequest.fromJson(Map<String, dynamic> json) =
      _$LoginRequestImpl.fromJson;

  @override
  String get email;
  @override
  String get password;

  /// Create a copy of LoginRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LoginRequestImplCopyWith<_$LoginRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) {
  return _AuthResponse.fromJson(json);
}

/// @nodoc
mixin _$AuthResponse {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Serializes this AuthResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthResponseCopyWith<AuthResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthResponseCopyWith<$Res> {
  factory $AuthResponseCopyWith(
    AuthResponse value,
    $Res Function(AuthResponse) then,
  ) = _$AuthResponseCopyWithImpl<$Res, AuthResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'access_token') String accessToken,
    @JsonKey(name: 'refresh_token') String refreshToken,
    @JsonKey(name: 'user_id') int userId,
    String name,
    String email,
  });
}

/// @nodoc
class _$AuthResponseCopyWithImpl<$Res, $Val extends AuthResponse>
    implements $AuthResponseCopyWith<$Res> {
  _$AuthResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
  }) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthResponseImplCopyWith<$Res>
    implements $AuthResponseCopyWith<$Res> {
  factory _$$AuthResponseImplCopyWith(
    _$AuthResponseImpl value,
    $Res Function(_$AuthResponseImpl) then,
  ) = __$$AuthResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'access_token') String accessToken,
    @JsonKey(name: 'refresh_token') String refreshToken,
    @JsonKey(name: 'user_id') int userId,
    String name,
    String email,
  });
}

/// @nodoc
class __$$AuthResponseImplCopyWithImpl<$Res>
    extends _$AuthResponseCopyWithImpl<$Res, _$AuthResponseImpl>
    implements _$$AuthResponseImplCopyWith<$Res> {
  __$$AuthResponseImplCopyWithImpl(
    _$AuthResponseImpl _value,
    $Res Function(_$AuthResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accessToken = null,
    Object? refreshToken = null,
    Object? userId = null,
    Object? name = null,
    Object? email = null,
  }) {
    return _then(
      _$AuthResponseImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthResponseImpl implements _AuthResponse {
  const _$AuthResponseImpl({
    @JsonKey(name: 'access_token') required this.accessToken,
    @JsonKey(name: 'refresh_token') required this.refreshToken,
    @JsonKey(name: 'user_id') required this.userId,
    required this.name,
    required this.email,
  });

  factory _$AuthResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthResponseImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;
  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String name;
  @override
  final String email;

  @override
  String toString() {
    return 'AuthResponse(accessToken: $accessToken, refreshToken: $refreshToken, userId: $userId, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthResponseImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, accessToken, refreshToken, userId, name, email);

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      __$$AuthResponseImplCopyWithImpl<_$AuthResponseImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthResponseImplToJson(this);
  }
}

abstract class _AuthResponse implements AuthResponse {
  const factory _AuthResponse({
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') required final String refreshToken,
    @JsonKey(name: 'user_id') required final int userId,
    required final String name,
    required final String email,
  }) = _$AuthResponseImpl;

  factory _AuthResponse.fromJson(Map<String, dynamic> json) =
      _$AuthResponseImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;
  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get name;
  @override
  String get email;

  /// Create a copy of AuthResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthResponseImplCopyWith<_$AuthResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SignUpRequest _$SignUpRequestFromJson(Map<String, dynamic> json) {
  return _SignUpRequest.fromJson(json);
}

/// @nodoc
mixin _$SignUpRequest {
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;

  /// Serializes this SignUpRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SignUpRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignUpRequestCopyWith<SignUpRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignUpRequestCopyWith<$Res> {
  factory $SignUpRequestCopyWith(
    SignUpRequest value,
    $Res Function(SignUpRequest) then,
  ) = _$SignUpRequestCopyWithImpl<$Res, SignUpRequest>;
  @useResult
  $Res call({String name, String email, String password});
}

/// @nodoc
class _$SignUpRequestCopyWithImpl<$Res, $Val extends SignUpRequest>
    implements $SignUpRequestCopyWith<$Res> {
  _$SignUpRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignUpRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? password = null,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SignUpRequestImplCopyWith<$Res>
    implements $SignUpRequestCopyWith<$Res> {
  factory _$$SignUpRequestImplCopyWith(
    _$SignUpRequestImpl value,
    $Res Function(_$SignUpRequestImpl) then,
  ) = __$$SignUpRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String email, String password});
}

/// @nodoc
class __$$SignUpRequestImplCopyWithImpl<$Res>
    extends _$SignUpRequestCopyWithImpl<$Res, _$SignUpRequestImpl>
    implements _$$SignUpRequestImplCopyWith<$Res> {
  __$$SignUpRequestImplCopyWithImpl(
    _$SignUpRequestImpl _value,
    $Res Function(_$SignUpRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignUpRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? email = null,
    Object? password = null,
  }) {
    return _then(
      _$SignUpRequestImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SignUpRequestImpl implements _SignUpRequest {
  const _$SignUpRequestImpl({
    required this.name,
    required this.email,
    required this.password,
  });

  factory _$SignUpRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$SignUpRequestImplFromJson(json);

  @override
  final String name;
  @override
  final String email;
  @override
  final String password;

  @override
  String toString() {
    return 'SignUpRequest(name: $name, email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignUpRequestImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, email, password);

  /// Create a copy of SignUpRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignUpRequestImplCopyWith<_$SignUpRequestImpl> get copyWith =>
      __$$SignUpRequestImplCopyWithImpl<_$SignUpRequestImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SignUpRequestImplToJson(this);
  }
}

abstract class _SignUpRequest implements SignUpRequest {
  const factory _SignUpRequest({
    required final String name,
    required final String email,
    required final String password,
  }) = _$SignUpRequestImpl;

  factory _SignUpRequest.fromJson(Map<String, dynamic> json) =
      _$SignUpRequestImpl.fromJson;

  @override
  String get name;
  @override
  String get email;
  @override
  String get password;

  /// Create a copy of SignUpRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignUpRequestImplCopyWith<_$SignUpRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SignUpResponse _$SignUpResponseFromJson(Map<String, dynamic> json) {
  return _SignUpResponse.fromJson(json);
}

/// @nodoc
mixin _$SignUpResponse {
  String get message => throw _privateConstructorUsedError;
  @JsonKey(name: 'verification_required')
  bool get verificationRequired => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;

  /// Serializes this SignUpResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SignUpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SignUpResponseCopyWith<SignUpResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SignUpResponseCopyWith<$Res> {
  factory $SignUpResponseCopyWith(
    SignUpResponse value,
    $Res Function(SignUpResponse) then,
  ) = _$SignUpResponseCopyWithImpl<$Res, SignUpResponse>;
  @useResult
  $Res call({
    String message,
    @JsonKey(name: 'verification_required') bool verificationRequired,
    String email,
  });
}

/// @nodoc
class _$SignUpResponseCopyWithImpl<$Res, $Val extends SignUpResponse>
    implements $SignUpResponseCopyWith<$Res> {
  _$SignUpResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SignUpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? verificationRequired = null,
    Object? email = null,
  }) {
    return _then(
      _value.copyWith(
            message: null == message
                ? _value.message
                : message // ignore: cast_nullable_to_non_nullable
                      as String,
            verificationRequired: null == verificationRequired
                ? _value.verificationRequired
                : verificationRequired // ignore: cast_nullable_to_non_nullable
                      as bool,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$SignUpResponseImplCopyWith<$Res>
    implements $SignUpResponseCopyWith<$Res> {
  factory _$$SignUpResponseImplCopyWith(
    _$SignUpResponseImpl value,
    $Res Function(_$SignUpResponseImpl) then,
  ) = __$$SignUpResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String message,
    @JsonKey(name: 'verification_required') bool verificationRequired,
    String email,
  });
}

/// @nodoc
class __$$SignUpResponseImplCopyWithImpl<$Res>
    extends _$SignUpResponseCopyWithImpl<$Res, _$SignUpResponseImpl>
    implements _$$SignUpResponseImplCopyWith<$Res> {
  __$$SignUpResponseImplCopyWithImpl(
    _$SignUpResponseImpl _value,
    $Res Function(_$SignUpResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of SignUpResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
    Object? verificationRequired = null,
    Object? email = null,
  }) {
    return _then(
      _$SignUpResponseImpl(
        message: null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
        verificationRequired: null == verificationRequired
            ? _value.verificationRequired
            : verificationRequired // ignore: cast_nullable_to_non_nullable
                  as bool,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SignUpResponseImpl implements _SignUpResponse {
  const _$SignUpResponseImpl({
    required this.message,
    @JsonKey(name: 'verification_required') required this.verificationRequired,
    required this.email,
  });

  factory _$SignUpResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$SignUpResponseImplFromJson(json);

  @override
  final String message;
  @override
  @JsonKey(name: 'verification_required')
  final bool verificationRequired;
  @override
  final String email;

  @override
  String toString() {
    return 'SignUpResponse(message: $message, verificationRequired: $verificationRequired, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignUpResponseImpl &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.verificationRequired, verificationRequired) ||
                other.verificationRequired == verificationRequired) &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, message, verificationRequired, email);

  /// Create a copy of SignUpResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SignUpResponseImplCopyWith<_$SignUpResponseImpl> get copyWith =>
      __$$SignUpResponseImplCopyWithImpl<_$SignUpResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$SignUpResponseImplToJson(this);
  }
}

abstract class _SignUpResponse implements SignUpResponse {
  const factory _SignUpResponse({
    required final String message,
    @JsonKey(name: 'verification_required')
    required final bool verificationRequired,
    required final String email,
  }) = _$SignUpResponseImpl;

  factory _SignUpResponse.fromJson(Map<String, dynamic> json) =
      _$SignUpResponseImpl.fromJson;

  @override
  String get message;
  @override
  @JsonKey(name: 'verification_required')
  bool get verificationRequired;
  @override
  String get email;

  /// Create a copy of SignUpResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SignUpResponseImplCopyWith<_$SignUpResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VerifyEmailRequest _$VerifyEmailRequestFromJson(Map<String, dynamic> json) {
  return _VerifyEmailRequest.fromJson(json);
}

/// @nodoc
mixin _$VerifyEmailRequest {
  String get email => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;

  /// Serializes this VerifyEmailRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VerifyEmailRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VerifyEmailRequestCopyWith<VerifyEmailRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VerifyEmailRequestCopyWith<$Res> {
  factory $VerifyEmailRequestCopyWith(
    VerifyEmailRequest value,
    $Res Function(VerifyEmailRequest) then,
  ) = _$VerifyEmailRequestCopyWithImpl<$Res, VerifyEmailRequest>;
  @useResult
  $Res call({String email, String code});
}

/// @nodoc
class _$VerifyEmailRequestCopyWithImpl<$Res, $Val extends VerifyEmailRequest>
    implements $VerifyEmailRequestCopyWith<$Res> {
  _$VerifyEmailRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VerifyEmailRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? code = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$VerifyEmailRequestImplCopyWith<$Res>
    implements $VerifyEmailRequestCopyWith<$Res> {
  factory _$$VerifyEmailRequestImplCopyWith(
    _$VerifyEmailRequestImpl value,
    $Res Function(_$VerifyEmailRequestImpl) then,
  ) = __$$VerifyEmailRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, String code});
}

/// @nodoc
class __$$VerifyEmailRequestImplCopyWithImpl<$Res>
    extends _$VerifyEmailRequestCopyWithImpl<$Res, _$VerifyEmailRequestImpl>
    implements _$$VerifyEmailRequestImplCopyWith<$Res> {
  __$$VerifyEmailRequestImplCopyWithImpl(
    _$VerifyEmailRequestImpl _value,
    $Res Function(_$VerifyEmailRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of VerifyEmailRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? code = null}) {
    return _then(
      _$VerifyEmailRequestImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$VerifyEmailRequestImpl implements _VerifyEmailRequest {
  const _$VerifyEmailRequestImpl({required this.email, required this.code});

  factory _$VerifyEmailRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$VerifyEmailRequestImplFromJson(json);

  @override
  final String email;
  @override
  final String code;

  @override
  String toString() {
    return 'VerifyEmailRequest(email: $email, code: $code)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VerifyEmailRequestImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.code, code) || other.code == code));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, code);

  /// Create a copy of VerifyEmailRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VerifyEmailRequestImplCopyWith<_$VerifyEmailRequestImpl> get copyWith =>
      __$$VerifyEmailRequestImplCopyWithImpl<_$VerifyEmailRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$VerifyEmailRequestImplToJson(this);
  }
}

abstract class _VerifyEmailRequest implements VerifyEmailRequest {
  const factory _VerifyEmailRequest({
    required final String email,
    required final String code,
  }) = _$VerifyEmailRequestImpl;

  factory _VerifyEmailRequest.fromJson(Map<String, dynamic> json) =
      _$VerifyEmailRequestImpl.fromJson;

  @override
  String get email;
  @override
  String get code;

  /// Create a copy of VerifyEmailRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VerifyEmailRequestImplCopyWith<_$VerifyEmailRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ResendCodeRequest _$ResendCodeRequestFromJson(Map<String, dynamic> json) {
  return _ResendCodeRequest.fromJson(json);
}

/// @nodoc
mixin _$ResendCodeRequest {
  String get email => throw _privateConstructorUsedError;
  String get purpose => throw _privateConstructorUsedError;

  /// Serializes this ResendCodeRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ResendCodeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ResendCodeRequestCopyWith<ResendCodeRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ResendCodeRequestCopyWith<$Res> {
  factory $ResendCodeRequestCopyWith(
    ResendCodeRequest value,
    $Res Function(ResendCodeRequest) then,
  ) = _$ResendCodeRequestCopyWithImpl<$Res, ResendCodeRequest>;
  @useResult
  $Res call({String email, String purpose});
}

/// @nodoc
class _$ResendCodeRequestCopyWithImpl<$Res, $Val extends ResendCodeRequest>
    implements $ResendCodeRequestCopyWith<$Res> {
  _$ResendCodeRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ResendCodeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? purpose = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            purpose: null == purpose
                ? _value.purpose
                : purpose // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ResendCodeRequestImplCopyWith<$Res>
    implements $ResendCodeRequestCopyWith<$Res> {
  factory _$$ResendCodeRequestImplCopyWith(
    _$ResendCodeRequestImpl value,
    $Res Function(_$ResendCodeRequestImpl) then,
  ) = __$$ResendCodeRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email, String purpose});
}

/// @nodoc
class __$$ResendCodeRequestImplCopyWithImpl<$Res>
    extends _$ResendCodeRequestCopyWithImpl<$Res, _$ResendCodeRequestImpl>
    implements _$$ResendCodeRequestImplCopyWith<$Res> {
  __$$ResendCodeRequestImplCopyWithImpl(
    _$ResendCodeRequestImpl _value,
    $Res Function(_$ResendCodeRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ResendCodeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null, Object? purpose = null}) {
    return _then(
      _$ResendCodeRequestImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        purpose: null == purpose
            ? _value.purpose
            : purpose // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ResendCodeRequestImpl implements _ResendCodeRequest {
  const _$ResendCodeRequestImpl({required this.email, required this.purpose});

  factory _$ResendCodeRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$ResendCodeRequestImplFromJson(json);

  @override
  final String email;
  @override
  final String purpose;

  @override
  String toString() {
    return 'ResendCodeRequest(email: $email, purpose: $purpose)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ResendCodeRequestImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.purpose, purpose) || other.purpose == purpose));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, purpose);

  /// Create a copy of ResendCodeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ResendCodeRequestImplCopyWith<_$ResendCodeRequestImpl> get copyWith =>
      __$$ResendCodeRequestImplCopyWithImpl<_$ResendCodeRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$ResendCodeRequestImplToJson(this);
  }
}

abstract class _ResendCodeRequest implements ResendCodeRequest {
  const factory _ResendCodeRequest({
    required final String email,
    required final String purpose,
  }) = _$ResendCodeRequestImpl;

  factory _ResendCodeRequest.fromJson(Map<String, dynamic> json) =
      _$ResendCodeRequestImpl.fromJson;

  @override
  String get email;
  @override
  String get purpose;

  /// Create a copy of ResendCodeRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ResendCodeRequestImplCopyWith<_$ResendCodeRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PasswordResetRequestBody _$PasswordResetRequestBodyFromJson(
  Map<String, dynamic> json,
) {
  return _PasswordResetRequestBody.fromJson(json);
}

/// @nodoc
mixin _$PasswordResetRequestBody {
  String get email => throw _privateConstructorUsedError;

  /// Serializes this PasswordResetRequestBody to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PasswordResetRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PasswordResetRequestBodyCopyWith<PasswordResetRequestBody> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordResetRequestBodyCopyWith<$Res> {
  factory $PasswordResetRequestBodyCopyWith(
    PasswordResetRequestBody value,
    $Res Function(PasswordResetRequestBody) then,
  ) = _$PasswordResetRequestBodyCopyWithImpl<$Res, PasswordResetRequestBody>;
  @useResult
  $Res call({String email});
}

/// @nodoc
class _$PasswordResetRequestBodyCopyWithImpl<
  $Res,
  $Val extends PasswordResetRequestBody
>
    implements $PasswordResetRequestBodyCopyWith<$Res> {
  _$PasswordResetRequestBodyCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PasswordResetRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null}) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PasswordResetRequestBodyImplCopyWith<$Res>
    implements $PasswordResetRequestBodyCopyWith<$Res> {
  factory _$$PasswordResetRequestBodyImplCopyWith(
    _$PasswordResetRequestBodyImpl value,
    $Res Function(_$PasswordResetRequestBodyImpl) then,
  ) = __$$PasswordResetRequestBodyImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String email});
}

/// @nodoc
class __$$PasswordResetRequestBodyImplCopyWithImpl<$Res>
    extends
        _$PasswordResetRequestBodyCopyWithImpl<
          $Res,
          _$PasswordResetRequestBodyImpl
        >
    implements _$$PasswordResetRequestBodyImplCopyWith<$Res> {
  __$$PasswordResetRequestBodyImplCopyWithImpl(
    _$PasswordResetRequestBodyImpl _value,
    $Res Function(_$PasswordResetRequestBodyImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PasswordResetRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? email = null}) {
    return _then(
      _$PasswordResetRequestBodyImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PasswordResetRequestBodyImpl implements _PasswordResetRequestBody {
  const _$PasswordResetRequestBodyImpl({required this.email});

  factory _$PasswordResetRequestBodyImpl.fromJson(Map<String, dynamic> json) =>
      _$$PasswordResetRequestBodyImplFromJson(json);

  @override
  final String email;

  @override
  String toString() {
    return 'PasswordResetRequestBody(email: $email)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordResetRequestBodyImpl &&
            (identical(other.email, email) || other.email == email));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email);

  /// Create a copy of PasswordResetRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordResetRequestBodyImplCopyWith<_$PasswordResetRequestBodyImpl>
  get copyWith =>
      __$$PasswordResetRequestBodyImplCopyWithImpl<
        _$PasswordResetRequestBodyImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PasswordResetRequestBodyImplToJson(this);
  }
}

abstract class _PasswordResetRequestBody implements PasswordResetRequestBody {
  const factory _PasswordResetRequestBody({required final String email}) =
      _$PasswordResetRequestBodyImpl;

  factory _PasswordResetRequestBody.fromJson(Map<String, dynamic> json) =
      _$PasswordResetRequestBodyImpl.fromJson;

  @override
  String get email;

  /// Create a copy of PasswordResetRequestBody
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PasswordResetRequestBodyImplCopyWith<_$PasswordResetRequestBodyImpl>
  get copyWith => throw _privateConstructorUsedError;
}

PasswordResetConfirmRequest _$PasswordResetConfirmRequestFromJson(
  Map<String, dynamic> json,
) {
  return _PasswordResetConfirmRequest.fromJson(json);
}

/// @nodoc
mixin _$PasswordResetConfirmRequest {
  String get email => throw _privateConstructorUsedError;
  String get code => throw _privateConstructorUsedError;
  @JsonKey(name: 'new_password')
  String get newPassword => throw _privateConstructorUsedError;

  /// Serializes this PasswordResetConfirmRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PasswordResetConfirmRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PasswordResetConfirmRequestCopyWith<PasswordResetConfirmRequest>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PasswordResetConfirmRequestCopyWith<$Res> {
  factory $PasswordResetConfirmRequestCopyWith(
    PasswordResetConfirmRequest value,
    $Res Function(PasswordResetConfirmRequest) then,
  ) =
      _$PasswordResetConfirmRequestCopyWithImpl<
        $Res,
        PasswordResetConfirmRequest
      >;
  @useResult
  $Res call({
    String email,
    String code,
    @JsonKey(name: 'new_password') String newPassword,
  });
}

/// @nodoc
class _$PasswordResetConfirmRequestCopyWithImpl<
  $Res,
  $Val extends PasswordResetConfirmRequest
>
    implements $PasswordResetConfirmRequestCopyWith<$Res> {
  _$PasswordResetConfirmRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PasswordResetConfirmRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? code = null,
    Object? newPassword = null,
  }) {
    return _then(
      _value.copyWith(
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            code: null == code
                ? _value.code
                : code // ignore: cast_nullable_to_non_nullable
                      as String,
            newPassword: null == newPassword
                ? _value.newPassword
                : newPassword // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PasswordResetConfirmRequestImplCopyWith<$Res>
    implements $PasswordResetConfirmRequestCopyWith<$Res> {
  factory _$$PasswordResetConfirmRequestImplCopyWith(
    _$PasswordResetConfirmRequestImpl value,
    $Res Function(_$PasswordResetConfirmRequestImpl) then,
  ) = __$$PasswordResetConfirmRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String email,
    String code,
    @JsonKey(name: 'new_password') String newPassword,
  });
}

/// @nodoc
class __$$PasswordResetConfirmRequestImplCopyWithImpl<$Res>
    extends
        _$PasswordResetConfirmRequestCopyWithImpl<
          $Res,
          _$PasswordResetConfirmRequestImpl
        >
    implements _$$PasswordResetConfirmRequestImplCopyWith<$Res> {
  __$$PasswordResetConfirmRequestImplCopyWithImpl(
    _$PasswordResetConfirmRequestImpl _value,
    $Res Function(_$PasswordResetConfirmRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PasswordResetConfirmRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? code = null,
    Object? newPassword = null,
  }) {
    return _then(
      _$PasswordResetConfirmRequestImpl(
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        code: null == code
            ? _value.code
            : code // ignore: cast_nullable_to_non_nullable
                  as String,
        newPassword: null == newPassword
            ? _value.newPassword
            : newPassword // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PasswordResetConfirmRequestImpl
    implements _PasswordResetConfirmRequest {
  const _$PasswordResetConfirmRequestImpl({
    required this.email,
    required this.code,
    @JsonKey(name: 'new_password') required this.newPassword,
  });

  factory _$PasswordResetConfirmRequestImpl.fromJson(
    Map<String, dynamic> json,
  ) => _$$PasswordResetConfirmRequestImplFromJson(json);

  @override
  final String email;
  @override
  final String code;
  @override
  @JsonKey(name: 'new_password')
  final String newPassword;

  @override
  String toString() {
    return 'PasswordResetConfirmRequest(email: $email, code: $code, newPassword: $newPassword)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PasswordResetConfirmRequestImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.code, code) || other.code == code) &&
            (identical(other.newPassword, newPassword) ||
                other.newPassword == newPassword));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, email, code, newPassword);

  /// Create a copy of PasswordResetConfirmRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PasswordResetConfirmRequestImplCopyWith<_$PasswordResetConfirmRequestImpl>
  get copyWith =>
      __$$PasswordResetConfirmRequestImplCopyWithImpl<
        _$PasswordResetConfirmRequestImpl
      >(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PasswordResetConfirmRequestImplToJson(this);
  }
}

abstract class _PasswordResetConfirmRequest
    implements PasswordResetConfirmRequest {
  const factory _PasswordResetConfirmRequest({
    required final String email,
    required final String code,
    @JsonKey(name: 'new_password') required final String newPassword,
  }) = _$PasswordResetConfirmRequestImpl;

  factory _PasswordResetConfirmRequest.fromJson(Map<String, dynamic> json) =
      _$PasswordResetConfirmRequestImpl.fromJson;

  @override
  String get email;
  @override
  String get code;
  @override
  @JsonKey(name: 'new_password')
  String get newPassword;

  /// Create a copy of PasswordResetConfirmRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PasswordResetConfirmRequestImplCopyWith<_$PasswordResetConfirmRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

RefreshResponse _$RefreshResponseFromJson(Map<String, dynamic> json) {
  return _RefreshResponse.fromJson(json);
}

/// @nodoc
mixin _$RefreshResponse {
  @JsonKey(name: 'access_token')
  String get accessToken => throw _privateConstructorUsedError;
  @JsonKey(name: 'refresh_token')
  String get refreshToken => throw _privateConstructorUsedError;

  /// Serializes this RefreshResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RefreshResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RefreshResponseCopyWith<RefreshResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RefreshResponseCopyWith<$Res> {
  factory $RefreshResponseCopyWith(
    RefreshResponse value,
    $Res Function(RefreshResponse) then,
  ) = _$RefreshResponseCopyWithImpl<$Res, RefreshResponse>;
  @useResult
  $Res call({
    @JsonKey(name: 'access_token') String accessToken,
    @JsonKey(name: 'refresh_token') String refreshToken,
  });
}

/// @nodoc
class _$RefreshResponseCopyWithImpl<$Res, $Val extends RefreshResponse>
    implements $RefreshResponseCopyWith<$Res> {
  _$RefreshResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RefreshResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accessToken = null, Object? refreshToken = null}) {
    return _then(
      _value.copyWith(
            accessToken: null == accessToken
                ? _value.accessToken
                : accessToken // ignore: cast_nullable_to_non_nullable
                      as String,
            refreshToken: null == refreshToken
                ? _value.refreshToken
                : refreshToken // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RefreshResponseImplCopyWith<$Res>
    implements $RefreshResponseCopyWith<$Res> {
  factory _$$RefreshResponseImplCopyWith(
    _$RefreshResponseImpl value,
    $Res Function(_$RefreshResponseImpl) then,
  ) = __$$RefreshResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'access_token') String accessToken,
    @JsonKey(name: 'refresh_token') String refreshToken,
  });
}

/// @nodoc
class __$$RefreshResponseImplCopyWithImpl<$Res>
    extends _$RefreshResponseCopyWithImpl<$Res, _$RefreshResponseImpl>
    implements _$$RefreshResponseImplCopyWith<$Res> {
  __$$RefreshResponseImplCopyWithImpl(
    _$RefreshResponseImpl _value,
    $Res Function(_$RefreshResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RefreshResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? accessToken = null, Object? refreshToken = null}) {
    return _then(
      _$RefreshResponseImpl(
        accessToken: null == accessToken
            ? _value.accessToken
            : accessToken // ignore: cast_nullable_to_non_nullable
                  as String,
        refreshToken: null == refreshToken
            ? _value.refreshToken
            : refreshToken // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RefreshResponseImpl implements _RefreshResponse {
  const _$RefreshResponseImpl({
    @JsonKey(name: 'access_token') required this.accessToken,
    @JsonKey(name: 'refresh_token') required this.refreshToken,
  });

  factory _$RefreshResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RefreshResponseImplFromJson(json);

  @override
  @JsonKey(name: 'access_token')
  final String accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  final String refreshToken;

  @override
  String toString() {
    return 'RefreshResponse(accessToken: $accessToken, refreshToken: $refreshToken)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshResponseImpl &&
            (identical(other.accessToken, accessToken) ||
                other.accessToken == accessToken) &&
            (identical(other.refreshToken, refreshToken) ||
                other.refreshToken == refreshToken));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, accessToken, refreshToken);

  /// Create a copy of RefreshResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshResponseImplCopyWith<_$RefreshResponseImpl> get copyWith =>
      __$$RefreshResponseImplCopyWithImpl<_$RefreshResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RefreshResponseImplToJson(this);
  }
}

abstract class _RefreshResponse implements RefreshResponse {
  const factory _RefreshResponse({
    @JsonKey(name: 'access_token') required final String accessToken,
    @JsonKey(name: 'refresh_token') required final String refreshToken,
  }) = _$RefreshResponseImpl;

  factory _RefreshResponse.fromJson(Map<String, dynamic> json) =
      _$RefreshResponseImpl.fromJson;

  @override
  @JsonKey(name: 'access_token')
  String get accessToken;
  @override
  @JsonKey(name: 'refresh_token')
  String get refreshToken;

  /// Create a copy of RefreshResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RefreshResponseImplCopyWith<_$RefreshResponseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) {
  return _UserProfile.fromJson(json);
}

/// @nodoc
mixin _$UserProfile {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'learning_goal')
  String? get learningGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_date')
  String? get targetDate => throw _privateConstructorUsedError;
  @JsonKey(name: 'profile_picture')
  String? get profilePicture => throw _privateConstructorUsedError;
  @JsonKey(name: 'oauth_provider')
  String? get oauthProvider => throw _privateConstructorUsedError;

  /// Serializes this UserProfile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserProfileCopyWith<UserProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserProfileCopyWith<$Res> {
  factory $UserProfileCopyWith(
    UserProfile value,
    $Res Function(UserProfile) then,
  ) = _$UserProfileCopyWithImpl<$Res, UserProfile>;
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') int userId,
    String name,
    String email,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    @JsonKey(name: 'profile_picture') String? profilePicture,
    @JsonKey(name: 'oauth_provider') String? oauthProvider,
  });
}

/// @nodoc
class _$UserProfileCopyWithImpl<$Res, $Val extends UserProfile>
    implements $UserProfileCopyWith<$Res> {
  _$UserProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? learningGoal = freezed,
    Object? targetDate = freezed,
    Object? profilePicture = freezed,
    Object? oauthProvider = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            learningGoal: freezed == learningGoal
                ? _value.learningGoal
                : learningGoal // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetDate: freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            profilePicture: freezed == profilePicture
                ? _value.profilePicture
                : profilePicture // ignore: cast_nullable_to_non_nullable
                      as String?,
            oauthProvider: freezed == oauthProvider
                ? _value.oauthProvider
                : oauthProvider // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserProfileImplCopyWith<$Res>
    implements $UserProfileCopyWith<$Res> {
  factory _$$UserProfileImplCopyWith(
    _$UserProfileImpl value,
    $Res Function(_$UserProfileImpl) then,
  ) = __$$UserProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') int userId,
    String name,
    String email,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    @JsonKey(name: 'profile_picture') String? profilePicture,
    @JsonKey(name: 'oauth_provider') String? oauthProvider,
  });
}

/// @nodoc
class __$$UserProfileImplCopyWithImpl<$Res>
    extends _$UserProfileCopyWithImpl<$Res, _$UserProfileImpl>
    implements _$$UserProfileImplCopyWith<$Res> {
  __$$UserProfileImplCopyWithImpl(
    _$UserProfileImpl _value,
    $Res Function(_$UserProfileImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? name = null,
    Object? email = null,
    Object? learningGoal = freezed,
    Object? targetDate = freezed,
    Object? profilePicture = freezed,
    Object? oauthProvider = freezed,
  }) {
    return _then(
      _$UserProfileImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        learningGoal: freezed == learningGoal
            ? _value.learningGoal
            : learningGoal // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetDate: freezed == targetDate
            ? _value.targetDate
            : targetDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        profilePicture: freezed == profilePicture
            ? _value.profilePicture
            : profilePicture // ignore: cast_nullable_to_non_nullable
                  as String?,
        oauthProvider: freezed == oauthProvider
            ? _value.oauthProvider
            : oauthProvider // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserProfileImpl implements _UserProfile {
  const _$UserProfileImpl({
    @JsonKey(name: 'user_id') required this.userId,
    required this.name,
    required this.email,
    @JsonKey(name: 'learning_goal') this.learningGoal,
    @JsonKey(name: 'target_date') this.targetDate,
    @JsonKey(name: 'profile_picture') this.profilePicture,
    @JsonKey(name: 'oauth_provider') this.oauthProvider,
  });

  factory _$UserProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserProfileImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  final String name;
  @override
  final String email;
  @override
  @JsonKey(name: 'learning_goal')
  final String? learningGoal;
  @override
  @JsonKey(name: 'target_date')
  final String? targetDate;
  @override
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  @override
  @JsonKey(name: 'oauth_provider')
  final String? oauthProvider;

  @override
  String toString() {
    return 'UserProfile(userId: $userId, name: $name, email: $email, learningGoal: $learningGoal, targetDate: $targetDate, profilePicture: $profilePicture, oauthProvider: $oauthProvider)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserProfileImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.learningGoal, learningGoal) ||
                other.learningGoal == learningGoal) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.profilePicture, profilePicture) ||
                other.profilePicture == profilePicture) &&
            (identical(other.oauthProvider, oauthProvider) ||
                other.oauthProvider == oauthProvider));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    name,
    email,
    learningGoal,
    targetDate,
    profilePicture,
    oauthProvider,
  );

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      __$$UserProfileImplCopyWithImpl<_$UserProfileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UserProfileImplToJson(this);
  }
}

abstract class _UserProfile implements UserProfile {
  const factory _UserProfile({
    @JsonKey(name: 'user_id') required final int userId,
    required final String name,
    required final String email,
    @JsonKey(name: 'learning_goal') final String? learningGoal,
    @JsonKey(name: 'target_date') final String? targetDate,
    @JsonKey(name: 'profile_picture') final String? profilePicture,
    @JsonKey(name: 'oauth_provider') final String? oauthProvider,
  }) = _$UserProfileImpl;

  factory _UserProfile.fromJson(Map<String, dynamic> json) =
      _$UserProfileImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  String get name;
  @override
  String get email;
  @override
  @JsonKey(name: 'learning_goal')
  String? get learningGoal;
  @override
  @JsonKey(name: 'target_date')
  String? get targetDate;
  @override
  @JsonKey(name: 'profile_picture')
  String? get profilePicture;
  @override
  @JsonKey(name: 'oauth_provider')
  String? get oauthProvider;

  /// Create a copy of UserProfile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserProfileImplCopyWith<_$UserProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UpdateProfileRequest _$UpdateProfileRequestFromJson(Map<String, dynamic> json) {
  return _UpdateProfileRequest.fromJson(json);
}

/// @nodoc
mixin _$UpdateProfileRequest {
  @JsonKey(name: 'user_id')
  int get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'learning_goal')
  String? get learningGoal => throw _privateConstructorUsedError;
  @JsonKey(name: 'target_date')
  String? get targetDate => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  String? get avatar => throw _privateConstructorUsedError;

  /// Serializes this UpdateProfileRequest to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UpdateProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UpdateProfileRequestCopyWith<UpdateProfileRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UpdateProfileRequestCopyWith<$Res> {
  factory $UpdateProfileRequestCopyWith(
    UpdateProfileRequest value,
    $Res Function(UpdateProfileRequest) then,
  ) = _$UpdateProfileRequestCopyWithImpl<$Res, UpdateProfileRequest>;
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') int userId,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    String? name,
    String? avatar,
  });
}

/// @nodoc
class _$UpdateProfileRequestCopyWithImpl<
  $Res,
  $Val extends UpdateProfileRequest
>
    implements $UpdateProfileRequestCopyWith<$Res> {
  _$UpdateProfileRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UpdateProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? learningGoal = freezed,
    Object? targetDate = freezed,
    Object? name = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int,
            learningGoal: freezed == learningGoal
                ? _value.learningGoal
                : learningGoal // ignore: cast_nullable_to_non_nullable
                      as String?,
            targetDate: freezed == targetDate
                ? _value.targetDate
                : targetDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            name: freezed == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String?,
            avatar: freezed == avatar
                ? _value.avatar
                : avatar // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UpdateProfileRequestImplCopyWith<$Res>
    implements $UpdateProfileRequestCopyWith<$Res> {
  factory _$$UpdateProfileRequestImplCopyWith(
    _$UpdateProfileRequestImpl value,
    $Res Function(_$UpdateProfileRequestImpl) then,
  ) = __$$UpdateProfileRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'user_id') int userId,
    @JsonKey(name: 'learning_goal') String? learningGoal,
    @JsonKey(name: 'target_date') String? targetDate,
    String? name,
    String? avatar,
  });
}

/// @nodoc
class __$$UpdateProfileRequestImplCopyWithImpl<$Res>
    extends _$UpdateProfileRequestCopyWithImpl<$Res, _$UpdateProfileRequestImpl>
    implements _$$UpdateProfileRequestImplCopyWith<$Res> {
  __$$UpdateProfileRequestImplCopyWithImpl(
    _$UpdateProfileRequestImpl _value,
    $Res Function(_$UpdateProfileRequestImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UpdateProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? learningGoal = freezed,
    Object? targetDate = freezed,
    Object? name = freezed,
    Object? avatar = freezed,
  }) {
    return _then(
      _$UpdateProfileRequestImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int,
        learningGoal: freezed == learningGoal
            ? _value.learningGoal
            : learningGoal // ignore: cast_nullable_to_non_nullable
                  as String?,
        targetDate: freezed == targetDate
            ? _value.targetDate
            : targetDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        name: freezed == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String?,
        avatar: freezed == avatar
            ? _value.avatar
            : avatar // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UpdateProfileRequestImpl implements _UpdateProfileRequest {
  const _$UpdateProfileRequestImpl({
    @JsonKey(name: 'user_id') required this.userId,
    @JsonKey(name: 'learning_goal') this.learningGoal,
    @JsonKey(name: 'target_date') this.targetDate,
    this.name,
    this.avatar,
  });

  factory _$UpdateProfileRequestImpl.fromJson(Map<String, dynamic> json) =>
      _$$UpdateProfileRequestImplFromJson(json);

  @override
  @JsonKey(name: 'user_id')
  final int userId;
  @override
  @JsonKey(name: 'learning_goal')
  final String? learningGoal;
  @override
  @JsonKey(name: 'target_date')
  final String? targetDate;
  @override
  final String? name;
  @override
  final String? avatar;

  @override
  String toString() {
    return 'UpdateProfileRequest(userId: $userId, learningGoal: $learningGoal, targetDate: $targetDate, name: $name, avatar: $avatar)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateProfileRequestImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.learningGoal, learningGoal) ||
                other.learningGoal == learningGoal) &&
            (identical(other.targetDate, targetDate) ||
                other.targetDate == targetDate) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.avatar, avatar) || other.avatar == avatar));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, learningGoal, targetDate, name, avatar);

  /// Create a copy of UpdateProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateProfileRequestImplCopyWith<_$UpdateProfileRequestImpl>
  get copyWith =>
      __$$UpdateProfileRequestImplCopyWithImpl<_$UpdateProfileRequestImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UpdateProfileRequestImplToJson(this);
  }
}

abstract class _UpdateProfileRequest implements UpdateProfileRequest {
  const factory _UpdateProfileRequest({
    @JsonKey(name: 'user_id') required final int userId,
    @JsonKey(name: 'learning_goal') final String? learningGoal,
    @JsonKey(name: 'target_date') final String? targetDate,
    final String? name,
    final String? avatar,
  }) = _$UpdateProfileRequestImpl;

  factory _UpdateProfileRequest.fromJson(Map<String, dynamic> json) =
      _$UpdateProfileRequestImpl.fromJson;

  @override
  @JsonKey(name: 'user_id')
  int get userId;
  @override
  @JsonKey(name: 'learning_goal')
  String? get learningGoal;
  @override
  @JsonKey(name: 'target_date')
  String? get targetDate;
  @override
  String? get name;
  @override
  String? get avatar;

  /// Create a copy of UpdateProfileRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UpdateProfileRequestImplCopyWith<_$UpdateProfileRequestImpl>
  get copyWith => throw _privateConstructorUsedError;
}

GoogleLoginUrlResponse _$GoogleLoginUrlResponseFromJson(
  Map<String, dynamic> json,
) {
  return _GoogleLoginUrlResponse.fromJson(json);
}

/// @nodoc
mixin _$GoogleLoginUrlResponse {
  @JsonKey(name: 'auth_url')
  String get authUrl => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;

  /// Serializes this GoogleLoginUrlResponse to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GoogleLoginUrlResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GoogleLoginUrlResponseCopyWith<GoogleLoginUrlResponse> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoogleLoginUrlResponseCopyWith<$Res> {
  factory $GoogleLoginUrlResponseCopyWith(
    GoogleLoginUrlResponse value,
    $Res Function(GoogleLoginUrlResponse) then,
  ) = _$GoogleLoginUrlResponseCopyWithImpl<$Res, GoogleLoginUrlResponse>;
  @useResult
  $Res call({@JsonKey(name: 'auth_url') String authUrl, String state});
}

/// @nodoc
class _$GoogleLoginUrlResponseCopyWithImpl<
  $Res,
  $Val extends GoogleLoginUrlResponse
>
    implements $GoogleLoginUrlResponseCopyWith<$Res> {
  _$GoogleLoginUrlResponseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GoogleLoginUrlResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? authUrl = null, Object? state = null}) {
    return _then(
      _value.copyWith(
            authUrl: null == authUrl
                ? _value.authUrl
                : authUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$GoogleLoginUrlResponseImplCopyWith<$Res>
    implements $GoogleLoginUrlResponseCopyWith<$Res> {
  factory _$$GoogleLoginUrlResponseImplCopyWith(
    _$GoogleLoginUrlResponseImpl value,
    $Res Function(_$GoogleLoginUrlResponseImpl) then,
  ) = __$$GoogleLoginUrlResponseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({@JsonKey(name: 'auth_url') String authUrl, String state});
}

/// @nodoc
class __$$GoogleLoginUrlResponseImplCopyWithImpl<$Res>
    extends
        _$GoogleLoginUrlResponseCopyWithImpl<$Res, _$GoogleLoginUrlResponseImpl>
    implements _$$GoogleLoginUrlResponseImplCopyWith<$Res> {
  __$$GoogleLoginUrlResponseImplCopyWithImpl(
    _$GoogleLoginUrlResponseImpl _value,
    $Res Function(_$GoogleLoginUrlResponseImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of GoogleLoginUrlResponse
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? authUrl = null, Object? state = null}) {
    return _then(
      _$GoogleLoginUrlResponseImpl(
        authUrl: null == authUrl
            ? _value.authUrl
            : authUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$GoogleLoginUrlResponseImpl implements _GoogleLoginUrlResponse {
  const _$GoogleLoginUrlResponseImpl({
    @JsonKey(name: 'auth_url') required this.authUrl,
    required this.state,
  });

  factory _$GoogleLoginUrlResponseImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoogleLoginUrlResponseImplFromJson(json);

  @override
  @JsonKey(name: 'auth_url')
  final String authUrl;
  @override
  final String state;

  @override
  String toString() {
    return 'GoogleLoginUrlResponse(authUrl: $authUrl, state: $state)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoogleLoginUrlResponseImpl &&
            (identical(other.authUrl, authUrl) || other.authUrl == authUrl) &&
            (identical(other.state, state) || other.state == state));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, authUrl, state);

  /// Create a copy of GoogleLoginUrlResponse
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GoogleLoginUrlResponseImplCopyWith<_$GoogleLoginUrlResponseImpl>
  get copyWith =>
      __$$GoogleLoginUrlResponseImplCopyWithImpl<_$GoogleLoginUrlResponseImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$GoogleLoginUrlResponseImplToJson(this);
  }
}

abstract class _GoogleLoginUrlResponse implements GoogleLoginUrlResponse {
  const factory _GoogleLoginUrlResponse({
    @JsonKey(name: 'auth_url') required final String authUrl,
    required final String state,
  }) = _$GoogleLoginUrlResponseImpl;

  factory _GoogleLoginUrlResponse.fromJson(Map<String, dynamic> json) =
      _$GoogleLoginUrlResponseImpl.fromJson;

  @override
  @JsonKey(name: 'auth_url')
  String get authUrl;
  @override
  String get state;

  /// Create a copy of GoogleLoginUrlResponse
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GoogleLoginUrlResponseImplCopyWith<_$GoogleLoginUrlResponseImpl>
  get copyWith => throw _privateConstructorUsedError;
}
