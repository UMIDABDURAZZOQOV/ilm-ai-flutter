import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/network/dio_client.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

const _callbackScheme = 'ilmai';

/// Ported from ilm-ai-mobile's Login/SignUp Google-OAuth handler: the
/// redirect_uri sent to the backend is a real HTTPS backend endpoint
/// (registered with Google), which the backend then bounces to the app's
/// custom `ilmai://` scheme carrying the issued tokens as query params.
Future<void> signInWithGoogle(WidgetRef ref) async {
  final urlRes = await ref.read(authRepositoryProvider).getGoogleLoginUrl('$apiBaseUrl/auth/google-callback-mobile');

  final result = await FlutterWebAuth2.authenticate(
    url: urlRes.authUrl,
    callbackUrlScheme: _callbackScheme,
  );

  final uri = Uri.parse(result);
  final accessToken = uri.queryParameters['access_token'];
  final refreshToken = uri.queryParameters['refresh_token'];
  final userIdRaw = uri.queryParameters['user_id'];
  if (accessToken == null || refreshToken == null || userIdRaw == null) {
    throw Exception('Invalid Google sign-in response');
  }

  await ref.read(authControllerProvider.notifier).login(AuthResponse(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userId: int.parse(userIdRaw),
        name: uri.queryParameters['name'] ?? '',
        email: uri.queryParameters['email'] ?? '',
      ));
}
