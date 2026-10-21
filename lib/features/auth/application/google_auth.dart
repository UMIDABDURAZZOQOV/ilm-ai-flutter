import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/network/api_contract.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';
export 'auth_controller.dart' show needsProfileSetupProvider;

const googleAuthTimeout = Duration(
  seconds: 30,
); // Network phase; browser allows time for 2FA.

String createCodeVerifier() => base64UrlEncode(
  List<int>.generate(48, (_) => Random.secure().nextInt(256)),
).replaceAll('=', '');
String codeChallenge(String verifier) => base64UrlEncode(
  sha256.convert(utf8.encode(verifier)).bytes,
).replaceAll('=', '');

String validatedGoogleCode(String callback, String state) {
  final uri = Uri.tryParse(callback);
  if (uri == null ||
      uri.scheme != 'ilmai' ||
      uri.host != 'auth' ||
      uri.path != '/callback' ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.queryParametersAll['state']?.length != 1 ||
      uri.queryParameters['state'] != state ||
      uri.queryParameters.containsKey('access_token') ||
      uri.queryParameters.containsKey('refresh_token')) {
    throw const GoogleAuthException(GoogleAuthFailure.invalidCallback);
  }
  final error = uri.queryParameters['error'];
  if (error != null) {
    throw GoogleAuthException(
      error == 'cancelled'
          ? GoogleAuthFailure.cancelled
          : GoogleAuthFailure.providerFailed,
    );
  }
  if (uri.queryParametersAll['code']?.length != 1 ||
      (uri.queryParameters['code'] ?? '').isEmpty) {
    throw const GoogleAuthException(GoogleAuthFailure.invalidCallback);
  }
  return uri.queryParameters['code']!;
}

Future<bool> signInWithGoogle(WidgetRef ref) async {
  final repo = ref.read(authRepositoryProvider);
  final verifier = createCodeVerifier();
  final url = await repo
      .prepareGoogleLogin(codeChallenge(verifier))
      .timeout(googleAuthTimeout);
  final result = await FlutterWebAuth2.authenticate(
    url: url.authUrl,
    callbackUrlScheme: 'ilmai',
  ).timeout(const Duration(minutes: 5));
  final code = validatedGoogleCode(result, url.state);
  if (!ref.context.mounted) return false;
  final data = await repo
      .exchangeMobileCode(code, verifier)
      .timeout(googleAuthTimeout);
  if (!ref.context.mounted) {
    await repo
        .logout(data['refresh_token'] as String)
        .catchError((Object _) {});
    return false;
  }
  await ref
      .read(authControllerProvider.notifier)
      .login(
        AuthResponse.fromJson(data),
        needsOnboarding: data['needs_onboarding'] == true,
      );
  return ref.read(needsProfileSetupProvider) == true;
}
