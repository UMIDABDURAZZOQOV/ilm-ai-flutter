import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'release_hardening_test.dart' show Adapter, reply, original;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureTokenStorage storage;
  late Dio dio;
  late int dispatched;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = SecureTokenStorage(const FlutterSecureStorage());
    await storage.saveTokens(original);
    dispatched = 0;
    dio = Dio(apiOptions())
      ..httpClientAdapter = Adapter((request) {
        dispatched++;
        return reply(200, {});
      })
      ..interceptors.add(AuthInterceptor(storage));
  });
  tearDown(() {
    dio.close(force: true);
    storage.dispose();
  });

  for (final url in [
    'https://untrusted.example/protected',
    '${apiBaseUrl.replaceFirst('://', '://user@')}/protected',
    '${Uri.parse(apiBaseUrl).replace(port: 444)}/protected',
  ]) {
    test(
      'shared authenticated client rejects another authority: $url',
      () async {
        await expectLater(dio.get(url), throwsA(isA<DioException>()));
        expect(dispatched, 0);
        expect(
          (await storage.getTokens())!.refreshToken,
          original.refreshToken,
        );
      },
    );
  }

  test('skipAuth cannot send a refresh credential to another origin', () async {
    await expectLater(
      dio.post(
        'https://untrusted.example/auth/logout',
        data: {'refresh_token': original.refreshToken},
        options: Options(extra: {'skipAuth': true}),
      ),
      throwsA(isA<DioException>()),
    );
    expect(dispatched, 0);
  });

  test(
    'same-origin requests retain authentication and never follow redirects',
    () async {
      RequestOptions? observed;
      dio.httpClientAdapter = Adapter((request) {
        observed = request;
        return reply(200, {});
      });
      await dio.get('/protected', options: Options(followRedirects: true));
      expect(
        observed!.headers['Authorization'],
        'Bearer ${original.accessToken}',
      );
      expect(observed!.followRedirects, false);
    },
  );
}
