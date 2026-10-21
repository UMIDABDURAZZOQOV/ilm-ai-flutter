import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/network/error_message.dart';
import 'package:ilm_ai_flutter/core/network/mobile_api.dart';
import 'package:ilm_ai_flutter/features/auth/application/google_auth.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  test(
    'malformed or non-Google authorization URL is rejected before the browser',
    () async {
      for (final value in [
        null,
        'http://accounts.google.com/',
        'https://example.test/',
      ]) {
        final dio = Dio()
          ..httpClientAdapter = Adapter(
            (_) => reply(200, {
              'auth_url': value,
              'state': 'expected',
              'mobile_auth_version': 2,
            }),
          );
        await expectLater(
          AuthRepository(dio).getGoogleLoginUrl(
            'https://api.example.test/auth/google-callback-mobile',
            challenge: 'a' * 43,
          ),
          throwsA(isA<InvalidApiResponseException>()),
        );
        dio.close(force: true);
      }
    },
  );
  test(
    'mobile namespace and anonymous catalogue hide legacy subjects',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..interceptors.add(MobileApiInterceptor());
      dio.httpClientAdapter = Adapter((request) {
        expect(request.path, '/mobile/skills/subjects');
        expect(request.extra['skipAuth'], isTrue);
        return reply(200, [
          for (final slug in ['math', 'biologiya'])
            {
              'id': slug == 'math' ? 1 : 2,
              'slug': slug,
              'name_uz': slug,
              'name_ru': slug,
              'name_en': slug,
            },
        ]);
      });
      addTearDown(() => dio.close(force: true));
      expect(
        (await SkillTreeRepository(dio).getSubjects()).map((s) => s.slug),
        ['biologiya'],
      );
    },
  );

  test(
    'an old backend reports compatibility instead of a fake empty course',
    () async {
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (_) => reply(404, {'detail': 'Not Found'}),
        );
      addTearDown(() => dio.close(force: true));
      await expectLater(
        SkillTreeRepository(dio).getSubjects(),
        throwsA(isA<ApiCompatibilityException>()),
      );
    },
  );

  test('API normalization prevents double-slash Google redirects', () {
    expect(
      normalizeApiBaseUrl('https://api.example.test/'),
      'https://api.example.test',
    );
    expect(
      normalizeApiBaseUrl('http://127.0.0.1:8000'),
      'http://127.0.0.1:8000',
    );
    for (final bad in [
      'api.example.test',
      'https://u:p@example.test',
      'https://example.test?token=x',
    ]) {
      expect(() => normalizeApiBaseUrl(bad), throwsArgumentError);
    }
  });

  test('Google preflight uses exact server redirect and S256 PKCE', () async {
    final requests = <RequestOptions>[];
    final dio = Dio()
      ..httpClientAdapter = Adapter((request) {
        requests.add(request);
        if (request.path.endsWith('/config')) {
          return reply(200, {
            'mobile_auth_version': 2,
            'pkce_method': 'S256',
            'code_exchange_path': '/auth/mobile/exchange',
            'google_configured': true,
            'redirect_uri':
                'https://staging.example.test/auth/google-callback-mobile',
          });
        }
        return reply(200, {
          'auth_url': 'https://accounts.google.com/o/oauth2/v2/auth',
          'state': 'test-state',
          'mobile_auth_version': 2,
        });
      });
    addTearDown(() => dio.close(force: true));
    final result = await AuthRepository(
      dio,
    ).prepareGoogleLogin(codeChallenge('v' * 64));
    expect(result.state, 'test-state');
    expect(requests, hasLength(2));
    expect(requests.first.extra['skipAuth'], isTrue);
    expect(
      requests.last.queryParameters['redirect_uri'],
      'https://staging.example.test/auth/google-callback-mobile',
    );
    expect(requests.last.queryParameters['code_challenge_method'], 'S256');
    expect(
      requests.last.queryParameters['code_challenge'],
      codeChallenge('v' * 64),
    );
  });

  test('unconfigured Google stops before authorization', () async {
    var calls = 0;
    final dio = Dio()
      ..httpClientAdapter = Adapter((_) {
        calls++;
        return reply(200, {
          'mobile_auth_version': 2,
          'pkce_method': 'S256',
          'code_exchange_path': '/auth/mobile/exchange',
          'google_configured': false,
        });
      });
    addTearDown(() => dio.close(force: true));
    await expectLater(
      AuthRepository(dio).prepareGoogleLogin('a' * 43),
      throwsA(
        isA<GoogleAuthException>().having(
          (e) => e.failure,
          'failure',
          GoogleAuthFailure.notConfigured,
        ),
      ),
    );
    expect(calls, 1);
    expect(
      extractError(
        const GoogleAuthException(GoogleAuthFailure.notConfigured),
        language: 'uz',
      ),
      contains('sozlanmagan'),
    );
  });

  test('valid callback returns only a code after state verification', () {
    expect(
      validatedGoogleCode(
        'ilmai://auth/callback?code=one-use&state=expected',
        'expected',
      ),
      'one-use',
    );
  });

  for (final callback in [
    'ilmai://auth/callback?code=x&state=wrong',
    'ilmai://other/callback?code=x&state=expected',
    'ilmai://auth/callback?code=x&state=expected&state=expected',
    'ilmai://auth/callback?code=x&state=expected&access_token=must-not-accept',
    'ilmai://auth/callback?error=cancelled&state=wrong',
  ]) {
    test('untrusted callback is rejected: $callback', () {
      expect(
        () => validatedGoogleCode(callback, 'expected'),
        throwsA(
          isA<GoogleAuthException>().having(
            (e) => e.failure,
            'failure',
            GoogleAuthFailure.invalidCallback,
          ),
        ),
      );
    });
  }

  test('verified cancellation differs from provider failure', () {
    expect(
      () => validatedGoogleCode(
        'ilmai://auth/callback?error=cancelled&state=expected',
        'expected',
      ),
      throwsA(
        isA<GoogleAuthException>().having(
          (e) => e.failure,
          'failure',
          GoogleAuthFailure.cancelled,
        ),
      ),
    );
    expect(
      () => validatedGoogleCode(
        'ilmai://auth/callback?error=oauth_failed&state=expected',
        'expected',
      ),
      throwsA(
        isA<GoogleAuthException>().having(
          (e) => e.failure,
          'failure',
          GoogleAuthFailure.providerFailed,
        ),
      ),
    );
  });
}
