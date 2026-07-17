import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Mirrors ilm-ai-mobile's `storage/tokenStore.ts` (single JSON blob under
/// `ilm_tokens`), but upgraded from plain AsyncStorage to encrypted
/// keychain/keystore storage since this is a fresh install with no legacy
/// migration to worry about.
class StoredTokens {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String? name;
  final String? email;

  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.name,
    this.email,
  });

  factory StoredTokens.fromJson(Map<String, dynamic> json) => StoredTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        userId: json['user_id'] as int,
        name: json['name'] as String?,
        email: json['email'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'user_id': userId,
        if (name != null) 'name': name,
        if (email != null) 'email': email,
      };

  StoredTokens copyWith({String? accessToken, String? refreshToken}) => StoredTokens(
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        userId: userId,
        name: name,
        email: email,
      );
}

class SecureTokenStorage {
  static const _key = 'ilm_tokens';
  final FlutterSecureStorage _storage;

  const SecureTokenStorage(this._storage);

  Future<StoredTokens?> getTokens() async {
    final raw = await _storage.read(key: _key);
    if (raw == null) return null;
    try {
      return StoredTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveTokens(StoredTokens tokens) => _storage.write(key: _key, value: jsonEncode(tokens.toJson()));

  Future<void> clearTokens() => _storage.delete(key: _key);
}
