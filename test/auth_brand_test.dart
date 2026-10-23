import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/router/app_router.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/widgets/ilmo_brand_mark.dart';
import 'package:ilm_ai_flutter/core/widgets/premium_button.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/login_screen.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/signup_screen.dart';

import 'support/load_review_fonts.dart';
import 'uiux_visual_review_test.dart' show reviewDio;
import 'release_hardening_test.dart' show Adapter, reply;

const _capture = bool.fromEnvironment('AUTH_BRAND_CAPTURE');
const _baseline = bool.fromEnvironment('AUTH_BRAND_BASELINE');

Future<GlobalKey> mountLogin(
  WidgetTester tester, {
  String language = 'ru',
  bool dark = false,
  Size physicalSize = const Size(720, 1600),
  double dpr = 1.875,
  double textScale = 1,
  bool reducedMotion = true,
  Dio? network,
  Widget screen = const LoginScreen(),
}) async {
  tester.view.physicalSize = physicalSize;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({PrefsKeys.language: language});
  final prefs = await PrefsService.create();
  final dio = network ?? reviewDio();
  addTearDown(() => dio.close(force: true));
  final key = GlobalKey();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        prefsServiceProvider.overrideWithValue(prefs),
        dioProvider.overrideWithValue(dio),
      ],
      child: RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(dark ? darkColors : lightColors),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              padding: const EdgeInsets.only(top: 24, bottom: 48),
              textScaler: TextScaler.linear(textScale),
              disableAnimations: reducedMotion,
            ),
            child: child!,
          ),
          home: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, key.currentContext!);
    }
  });
  await tester.pump();
  return key;
}

Future<void> captureLogin(
  WidgetTester tester,
  GlobalKey key,
  String name,
) async {
  if (!_capture) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.875);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    final stage = _baseline ? 'before' : 'after';
    final file = File('.dart_tool/auth-brand-review/$stage/$name.png');
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadReviewFonts);
  for (final language in ['uz', 'ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets('A12 login $language/${dark ? "dark" : "light"}', (
        tester,
      ) async {
        final key = await mountLogin(tester, language: language, dark: dark);
        expect(tester.takeException(), isNull);
        expect(find.text('ILM AI'), findsOneWidget);
        expect(find.byType(IlmoBrandMark), findsOneWidget);
        final image = tester.widget<Image>(find.byType(Image));
        expect(
          ((image.image as ResizeImage).imageProvider as AssetImage).assetName,
          IlmoBrandMark.asset,
        );
        expect(image.fit, BoxFit.contain);
        expect(image.width, image.height);
        expect(image.excludeFromSemantics, isTrue);
        final rect = tester.getRect(find.byType(IlmoBrandMark));
        expect(rect.center.dx, closeTo(192, .1));
        expect(
          find.byKey(const ValueKey('login_google')).hitTestable(),
          findsOneWidget,
        );
        await captureLogin(tester, key, '$language-${dark ? "dark" : "light"}');
        if (language == 'ru') {
          await expectLater(
            find.byKey(key),
            matchesGoldenFile(
              'goldens/auth_login_${dark ? "dark" : "light"}.png',
            ),
          );
        }
      });
      for (final size in [const Size(320, 568), const Size(640, 360)]) {
        testWidgets('login 200% $language/$dark/$size', (tester) async {
          final semantics = tester.ensureSemantics();
          await mountLogin(
            tester,
            language: language,
            dark: dark,
            physicalSize: size,
            dpr: 1,
            textScale: 2,
          );
          expect(tester.takeException(), isNull);
          semantics.dispose();
          final button = find.byKey(const ValueKey('login_google'));
          await tester.ensureVisible(button);
          await tester.pumpAndSettle();
          expect(button.hitTestable(), findsOneWidget);
          expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
          expect(tester.takeException(), isNull);
        });
      }
      testWidgets('branded loading and network error $language/$dark', (
        tester,
      ) async {
        final pending = Completer<void>();
        var attempts = 0;
        final dio = Dio(BaseOptions(baseUrl: 'https://isolated.example.test'))
          ..httpClientAdapter = Adapter((request) async {
            if (request.path == '/health') return reply(200, {});
            expect(request.path, '/auth/mobile/config');
            attempts++;
            await pending.future;
            throw DioException(
              requestOptions: request,
              type: DioExceptionType.connectionError,
            );
          });
        final key = await mountLogin(
          tester,
          language: language,
          dark: dark,
          network: dio,
        );
        final button = find.byKey(const ValueKey('login_google'));
        await tester.tap(button);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(tester.widget<PremiumButton>(button).onPressed, isNull);
        expect(find.byType(IlmoBrandMark), findsOneWidget);
        expect(
          tester
              .widget<CircularProgressIndicator>(
                find.byType(CircularProgressIndicator),
              )
              .value,
          .75,
        );
        await captureLogin(
          tester,
          key,
          '$language-${dark ? "dark" : "light"}-loading',
        );
        pending.complete();
        await tester.pumpAndSettle();
        final message = switch (language) {
          'ru' => 'Нет подключения к интернету. Проверьте соединение.',
          'en' => 'No internet connection. Please check your network.',
          _ => "Internet aloqasi yo'q. Tarmoq ulanishini tekshiring.",
        };
        expect(find.text(message), findsOneWidget);
        expect(tester.widget<PremiumButton>(button).onPressed, isNotNull);
        expect(attempts, 1);
        expect(find.byType(IlmoBrandMark), findsOneWidget);
        expect(tester.takeException(), isNull);
        await captureLogin(
          tester,
          key,
          '$language-${dark ? "dark" : "light"}-error',
        );
      });
    }
  }
  testWidgets('entrance settles quickly with no repeating animation', (
    tester,
  ) async {
    await mountLogin(tester, reducedMotion: false);
    expect(tester.binding.hasScheduledFrame, isFalse);
    for (final fade in tester.widgetList<FadeTransition>(
      find.byType(FadeTransition),
    )) {
      expect(fade.opacity.value, 1);
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets('retained signup uses the same official face', (tester) async {
    await mountLogin(tester, screen: const SignUpScreen());
    expect(find.byType(IlmoBrandMark), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('no Flutter screen references the retired brand asset', () {
    final oldReferences = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .where((f) => f.readAsStringSync().contains('assets/icons/icon.png'));
    expect(oldReferences, isEmpty);
    expect(File('assets/icons/icon.png').existsSync(), isTrue);
  });
  testWidgets(
    'mocked signed-out session redirects to branded login without clearing preferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_complete': true,
        PrefsKeys.language: 'ru',
        'auth_brand_preserved_probe': 'saved-learning-data',
      });
      final prefs = await PrefsService.create();
      final dio = reviewDio();
      addTearDown(() => dio.close(force: true));
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          dioProvider.overrideWithValue(dio),
          authControllerProvider.overrideWith(_PreviewAuth.new),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      final router = container.read(routerProvider);
      (container.read(authControllerProvider.notifier) as _PreviewAuth)
          .simulateSignedOut();
      router.go('/settings');
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            theme: buildAppTheme(lightColors),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(router.state.matchedLocation, '/login');
      expect(find.byType(IlmoBrandMark), findsOneWidget);
      expect(
        prefs.getString('auth_brand_preserved_probe'),
        'saved-learning-data',
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _PreviewAuth extends AuthController {
  @override
  Future<StoredTokens?> build() async => const StoredTokens(
    accessToken: 'isolated-test',
    refreshToken: 'isolated-test',
    userId: 7,
  );

  void simulateSignedOut() => state = const AsyncData(null);
}
