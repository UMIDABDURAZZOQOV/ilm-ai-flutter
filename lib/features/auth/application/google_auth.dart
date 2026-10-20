import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/network/dio_client.dart';
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

Future<bool> signInWithGoogle(WidgetRef ref) async {
  final repo = ref.read(authRepositoryProvider);
  final verifier = createCodeVerifier();
  final url = await repo
      .getGoogleLoginUrl(
        '$apiBaseUrl/auth/google-callback-mobile',
        challenge: codeChallenge(verifier),
      )
      .timeout(googleAuthTimeout);
  final result = await FlutterWebAuth2.authenticate(
    url: url.authUrl,
    callbackUrlScheme: 'ilmai',
  ).timeout(const Duration(minutes: 5));
  final uri = Uri.parse(result);
  if (uri.queryParameters['error'] != null) {
    throw StateError('google_sign_in_failed');
  }
  if (uri.scheme != 'ilmai' ||
      uri.host != 'auth' ||
      uri.path != '/callback' ||
      uri.queryParameters['state'] != url.state ||
      uri.queryParameters['code'] == null) {
    throw StateError('invalid_google_callback');
  }
  final data = await repo
      .exchangeMobileCode(uri.queryParameters['code']!, verifier)
      .timeout(googleAuthTimeout);
  await ref
      .read(authControllerProvider.notifier)
      .login(
        AuthResponse.fromJson(data),
        needsOnboarding: data['needs_onboarding'] == true,
      );
  return ref.read(needsProfileSetupProvider) == true;
}
