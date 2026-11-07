import 'dart:convert';
import 'dart:async';

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
  final bool? needsOnboarding;

  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    this.name,
    this.email,
    this.needsOnboarding,
  });

  factory StoredTokens.fromJson(Map<String, dynamic> json) => StoredTokens(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    userId: json['user_id'] as int,
    name: json['name'] as String?,
    email: json['email'] as String?,
    needsOnboarding: json['needs_onboarding'] as bool?,
  );

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'user_id': userId,
    if (name != null) 'name': name,
    if (email != null) 'email': email,
    if (needsOnboarding != null) 'needs_onboarding': needsOnboarding,
  };

  StoredTokens copyWith({
    String? accessToken,
    String? refreshToken,
    String? name,
    String? email,
    bool? needsOnboarding,
  }) => StoredTokens(
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    userId: userId,
    name: name ?? this.name,
    email: email ?? this.email,
    needsOnboarding: needsOnboarding ?? this.needsOnboarding,
  );
}

class SecureTokenStorage {
  static const _key = 'ilm_tokens';
  final FlutterSecureStorage _storage;
  final _changes = StreamController<StoredTokens?>.broadcast();
  Future<void> _pending = Future.value();
  bool _loaded = false;
  StoredTokens? _cached;
  int _sessionGeneration = 0;

  /// Changes on login/logout, including a new login to the same account.
  /// Ordinary token refreshes and profile edits preserve the logical session.
  int get sessionGeneration => _sessionGeneration;
  SecureTokenStorage(this._storage);

  void dispose() {
    _cached = null;
    _loaded = false;
    unawaited(_changes.close());
  }

  Stream<StoredTokens?> get changes => _changes.stream;

  Future<T> _serial<T>(Future<T> Function() action) {
    final task = _pending.then((_) => action());
    _pending = task.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return task;
  }

  Future<StoredTokens?> _read() async {
    if (_loaded) return _cached;
    final raw = await _storage.read(key: _key);
    StoredTokens? tokens;
    try {
      tokens = raw == null
          ? null
          : StoredTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      tokens = null;
    }
    _cached = tokens;
    _loaded = true;
    return tokens;
  }

  Future<StoredTokens?> getTokens() => _serial(_read);

  Future<void> saveTokens(StoredTokens tokens) => _serial(() async {
    await _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
    _cached = tokens;
    _loaded = true;
    _sessionGeneration++;
    if (!_changes.isClosed) _changes.add(tokens);
  });

  Future<StoredTokens?> updateTokens(
    StoredTokens Function(StoredTokens) change,
  ) => _serial(() async {
    final current = await _read();
    if (current == null) return null;
    final updated = change(current);
    await _storage.write(key: _key, value: jsonEncode(updated.toJson()));
    _cached = updated;
    _loaded = true;
    if (!_changes.isClosed) _changes.add(updated);
    return updated;
  });

  Future<bool> replaceRefresh(String expected, String access, String refresh) =>
      _serial(() async {
        final current = await _read();
        if (current == null || current.refreshToken != expected) return false;
        final updated = current.copyWith(
          accessToken: access,
          refreshToken: refresh,
        );
        await _storage.write(key: _key, value: jsonEncode(updated.toJson()));
        _cached = updated;
        _loaded = true;
        if (!_changes.isClosed) _changes.add(updated);
        return true;
      });

  Future<void> clearTokens({String? expectedRefresh}) => _serial(() async {
    final current = await _read();
    if (expectedRefresh != null && current?.refreshToken != expectedRefresh) {
      return;
    }
    await _storage.delete(key: _key);
    _cached = null;
    _loaded = true;
    _sessionGeneration++;
    if (!_changes.isClosed) _changes.add(null);
  });
}
