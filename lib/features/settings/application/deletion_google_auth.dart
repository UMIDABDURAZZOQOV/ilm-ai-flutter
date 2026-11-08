import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../../../core/config/integrated_beta.dart';
import '../../auth/application/google_auth.dart';
import '../data/account_deletion_repository.dart';

String validatedDeletionCode(String callback, String state) {
  final uri = Uri.tryParse(callback);
  if (uri == null ||
      uri.scheme != mobileAppScheme ||
      uri.host != 'deletion' ||
      uri.path != '/callback' ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      uri.queryParametersAll['state']?.length != 1 ||
      uri.queryParameters['state'] != state ||
      uri.queryParameters.containsKey('access_token') ||
      uri.queryParameters.containsKey('refresh_token') ||
      uri.queryParameters.containsKey('error') ||
      uri.queryParametersAll['code']?.length != 1 ||
      !RegExp(
        r'^[A-Za-z0-9_-]{43}$',
      ).hasMatch(uri.queryParameters['code'] ?? '')) {
    throw const FormatException('Google reauthentication was not confirmed');
  }
  return uri.queryParameters['code']!;
}

typedef GoogleDeletionReauth =
    Future<DeletionProof> Function(AccountDeletionRepository, CancelToken);
final googleDeletionReauthProvider = Provider<GoogleDeletionReauth>(
  (ref) => (repo, cancel) async {
    final verifier = createCodeVerifier();
    final prepared = await repo
        .prepareGoogle(codeChallenge(verifier), cancel)
        .timeout(googleAuthTimeout);
    final uri = Uri.tryParse(prepared['auth_url']);
    final state = prepared['state'] as String;
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != 'accounts.google.com' ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        uri.queryParameters['state'] != state ||
        !state.startsWith('del_')) {
      throw const FormatException('Invalid Google reauthentication origin');
    }
    final callback = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: mobileAppScheme,
    ).timeout(const Duration(minutes: 5));
      if (cancel.isCancelled) throw cancel.cancelError!;
    return repo
        .exchangeProof(validatedDeletionCode(callback, state), verifier, cancel)
        .timeout(googleAuthTimeout);
  },
);
