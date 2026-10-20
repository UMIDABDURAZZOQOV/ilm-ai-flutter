import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Tristate;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/core/widgets/duo_chrome.dart';
import 'package:ilm_ai_flutter/core/widgets/mascot_image.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/application/google_auth.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_models.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/onboarding/data/onboarding_draft.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/duo_onboarding_screen.dart';
import 'package:ilm_ai_flutter/features/skills/presentation/ai_tutor_widget.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_extras_repository.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/onboarding/presentation/onboarding_screen.dart';

class Adapter implements HttpClientAdapter {
  final FutureOr<ResponseBody> Function(RequestOptions) handle;
  Adapter(this.handle);
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async => handle(options);
  @override
  void close({bool force = false}) {}
}

ResponseBody reply(int status, Object data) => ResponseBody.fromString(
  jsonEncode(data),
  status,
  headers: {
    Headers.contentTypeHeader: ['application/json'],
  },
);
const original = StoredTokens(
  accessToken: 'old-access',
  refreshToken: 'old-refresh',
  userId: 1,
  name: 'Old name',
  needsOnboarding: false,
);

class SessionRepo extends AuthRepository {
  bool pending;
  Object? failure;
  String? savedName;
  int? savedAge;
  SessionRepo({this.pending = false, this.failure}) : super(Dio());
  @override
  Future<bool> needsOnboarding(int userId) async {
    if (failure != null) throw failure!;
    return pending;
  }

  @override
  Future<String> updateProfile(UpdateProfileRequest req) async => 'ok';
  @override
  Future<void> completeOnboarding({
    required int userId,
    required String name,
    required int age,
  }) async {
    savedName = name;
    savedAge = age;
    pending = false;
  }
}

class LoggedOutTest extends AuthController {
  @override
  Future<StoredTokens?> build() async => null;
}

class DelayedTutor extends SkillExtrasRepository {
  final Completer<String> response = Completer();
  DelayedTutor() : super(Dio(), 'en');
  @override
  Future<String> explain({
    required String questionText,
    List<String>? options,
    required String correctAnswer,
    String? userAnswer,
    required String lang,
  }) => response.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SecureTokenStorage storage;
  late PrefsService prefs;
  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    storage = SecureTokenStorage(const FlutterSecureStorage());
    prefs = await PrefsService.create();
  });

  Dio client(Adapter adapter) {
    final transport = Dio(apiOptions())..httpClientAdapter = adapter;
    return Dio(apiOptions())
      ..httpClientAdapter = adapter
      ..interceptors.add(AuthInterceptor(storage, transport: transport));
  }

  test(
    'refresh updates secure storage and a concurrent name edit preserves rotated tokens',
    () async {
      await storage.saveTokens(original);
      final dio = client(
        Adapter((request) {
          if (request.path == '/auth/refresh') {
            return reply(200, {
              'access_token': 'new-access',
              'refresh_token': 'new-refresh',
            });
          }
          return reply(
            request.headers['Authorization'] == 'Bearer new-access' ? 200 : 401,
            {},
          );
        }),
      );
      await dio.get('/protected');
      await storage.updateTokens(
        (current) => current.copyWith(name: 'New name'),
      );
      final latest = await storage.getTokens();
      expect(latest!.refreshToken, 'new-refresh');
      expect(latest.name, 'New name');
    },
  );

  for (final status in [500, 503, 401]) {
    test('refresh HTTP $status clears only a confirmed 401', () async {
      await storage.saveTokens(original);
      final dio = client(
        Adapter(
          (request) =>
              reply(request.path == '/auth/refresh' ? status : 401, {}),
        ),
      );
      await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));
      expect(await storage.getTokens(), status == 401 ? isNull : isNotNull);
    });
  }

  test(
    'an endpoint 500 after successful refresh preserves the new session',
    () async {
      await storage.saveTokens(original);
      final dio = client(
        Adapter((request) {
          if (request.path == '/auth/refresh') {
            return reply(200, {
              'access_token': 'new',
              'refresh_token': 'rotated',
            });
          }
          return reply(
            request.headers['Authorization'] == 'Bearer new' ? 500 : 401,
            {},
          );
        }),
      );
      await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));
      expect((await storage.getTokens())!.refreshToken, 'rotated');
    },
  );

  test(
    'malformed refresh response settles the request without clearing credentials',
    () async {
      await storage.saveTokens(original);
      final dio = client(
        Adapter(
          (request) =>
              reply(request.path == '/auth/refresh' ? 200 : 401, ['invalid']),
        ),
      );
      await expectLater(
        dio.get('/protected').timeout(const Duration(seconds: 2)),
        throwsA(isA<DioException>()),
      );
      expect(await storage.getTokens(), isNotNull);
    },
  );

  test('logout during refresh cannot resurrect the account', () async {
    await storage.saveTokens(original);
    final began = Completer<void>();
    final release = Completer<void>();
    final dio = client(
      Adapter((request) async {
        if (request.path == '/auth/refresh') {
          began.complete();
          await release.future;
          return reply(200, {
            'access_token': 'new',
            'refresh_token': 'rotated',
          });
        }
        return reply(request.path == '/auth/logout' ? 200 : 401, {});
      }),
    );
    final pending = expectLater(
      dio.get('/protected'),
      throwsA(isA<DioException>()),
    );
    await began.future;
    await storage.clearTokens();
    release.complete();
    await pending;
    expect(await storage.getTokens(), isNull);
  });

  test(
    'several expired requests rotate once and all retry with the new token',
    () async {
      await storage.saveTokens(original);
      var refreshes = 0;
      final dio = client(
        Adapter((request) async {
          if (request.path == '/auth/refresh') {
            refreshes++;
            return reply(200, {
              'access_token': 'new',
              'refresh_token': 'rotated',
            });
          }
          return reply(
            request.headers['Authorization'] == 'Bearer new' ? 200 : 401,
            {},
          );
        }),
      );
      await Future.wait(List.generate(3, (_) => dio.get('/protected')));
      expect(refreshes, 1);
    },
  );

  ProviderContainer session(SessionRepo repo) => ProviderContainer(
    overrides: [
      secureTokenStorageProvider.overrideWithValue(storage),
      authRepositoryProvider.overrideWithValue(repo),
      prefsServiceProvider.overrideWithValue(prefs),
      dioProvider.overrideWithValue(
        Dio(apiOptions())
          ..httpClientAdapter = Adapter(
            (_) => reply(200, {'preferences': null}),
          ),
      ),
    ],
  );

  test('incomplete profile is recovered from the API on cold start', () async {
    await storage.saveTokens(original.copyWith(needsOnboarding: false));
    final container = session(SessionRepo(pending: true));
    addTearDown(container.dispose);
    await container.read(authControllerProvider.future);
    expect(container.read(needsProfileSetupProvider), isTrue);
    expect((await storage.getTokens())!.needsOnboarding, isTrue);
  });

  test('offline restore retains a known session', () async {
    await storage.saveTokens(original);
    final container = session(SessionRepo(failure: StateError('offline')));
    addTearDown(container.dispose);
    expect(await container.read(authControllerProvider.future), isNotNull);
    expect(container.read(sessionRestoreErrorProvider), isNull);
  });

  test(
    'a completed guest form is adopted once and submitted without repeating onboarding',
    () async {
      await OnboardingDraftStore(prefs).save(null, {
        'completed': true,
        'name': 'Guest learner',
        'age': '12',
        'subject': 'math',
        'daily_goal': 30,
      });
      final repo = SessionRepo(pending: true);
      final container = session(repo);
      addTearDown(container.dispose);
      await container.read(authControllerProvider.future);
      await container
          .read(authControllerProvider.notifier)
          .login(
            const AuthResponse(
              accessToken: 'a',
              refreshToken: 'r',
              userId: 1,
              name: 'Google name',
              email: 'learner@example.test',
            ),
            needsOnboarding: true,
          );
      expect(repo.savedName, 'Guest learner');
      expect(repo.savedAge, 12);
      expect(container.read(needsProfileSetupProvider), isFalse);
      expect(prefs.getInt('daily_goal_1'), 30);
      expect(OnboardingDraftStore(prefs).read(null), isNull);
      expect(await OnboardingDraftStore(prefs).adopt(2), isNull);
    },
  );

  test('PKCE verifier and challenge match RFC 7636', () {
    expect(
      codeChallenge('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk'),
      'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    );
    expect(createCodeVerifier().length, 64);
  });

  test('API deadlines are finite for connect, send, receive', () {
    final options = apiOptions();
    expect(options.connectTimeout, isNotNull);
    expect(options.sendTimeout, isNotNull);
    expect(options.receiveTimeout, isNotNull);
  });

  testWidgets('system palette reacts to OS brightness', (tester) async {
    final container = ProviderContainer(
      overrides: [prefsServiceProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (_, ref, _) {
            ref.watch(resolvedColorsProvider);
            return const SizedBox();
          },
        ),
      ),
    );
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    expect(container.read(resolvedColorsProvider), lightColors);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pump();
    expect(container.read(resolvedColorsProvider), darkColors);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.pump(const Duration(milliseconds: 1));
  });

  testWidgets(
    '3D buttons support keyboard activation and announced selection',
    (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(lightColors),
          home: Scaffold(
            body: Column(
              children: [
                Duo3DButton(
                  onPressed: () => taps++,
                  color: BrandPalette.accentOrange,
                  child: const Text('Continue'),
                ),
                DuoChoiceCard(
                  text: 'Choice',
                  selected: true,
                  answered: false,
                  isCorrectOption: true,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
      final semantics = tester.ensureSemantics();
      expect(
        tester
            .getSemantics(find.text('Choice'))
            .getSemanticsData()
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );
      semantics.dispose();
      expect(foregroundOn(BrandPalette.accentOrange), isNot(Colors.white));
    },
  );

  testWidgets('Ilmo is static with Reduce Motion', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MascotImage(pose: MascotPose.happy),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  for (final size in [const Size(320, 568), const Size(640, 360)]) {
    testWidgets(
      'welcome remains scrollable without overflow at $size and large text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [prefsServiceProvider.overrideWithValue(prefs)],
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              home: const MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(1.7),
                  disableAnimations: true,
                ),
                child: OnboardingScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const ValueKey('welcome_have_account_btn')),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final kind in [
    DioExceptionType.connectionError,
    DioExceptionType.receiveTimeout,
  ]) {
    test('refresh $kind preserves stored credentials', () async {
      await storage.saveTokens(original);
      final dio = client(
        Adapter((request) {
          if (request.path == '/auth/refresh') {
            throw DioException(requestOptions: request, type: kind);
          }
          return reply(401, {});
        }),
      );
      await expectLater(dio.get('/protected'), throwsA(isA<DioException>()));
      expect((await storage.getTokens())!.refreshToken, 'old-refresh');
    });
  }

  test(
    'a newer goal edit is sent after an in-flight update, never overwritten',
    () async {
      final first = Completer<void>();
      final began = Completer<void>();
      final sent = <int>[];
      final dio = Dio(apiOptions())
        ..httpClientAdapter = Adapter((request) async {
          sent.add((request.data as Map)['daily_goal_xp'] as int);
          if (sent.length == 1) {
            began.complete();
            await first.future;
          }
          return reply(200, {});
        });
      final settings = LearningPreferences(dio, prefs);
      await settings.save(1, {'daily_goal_xp': 10});
      await began.future;
      await settings.save(1, {'daily_goal_xp': 50});
      first.complete();
      await settings.flush(1);
      expect(sent, [10, 50]);
      expect(prefs.getBool('study_preferences_dirty_1'), isFalse);
      expect(prefs.getInt('daily_goal_2'), isNull);
    },
  );

  testWidgets(
    'an unfinished guest form restores the entered name, age and step',
    (tester) async {
      await OnboardingDraftStore(
        prefs,
      ).save(null, {'step': 11, 'name': 'Sardor', 'age': '12'});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            authControllerProvider.overrideWith(LoggedOutTest.new),
          ],
          child: MaterialApp(
            theme: buildAppTheme(lightColors),
            home: const DuoOnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sardor'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'AI completion after navigating away does not call setState on a disposed widget',
    (tester) async {
      final tutor = DelayedTutor();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsServiceProvider.overrideWithValue(prefs),
            skillExtrasRepositoryProvider.overrideWithValue(tutor),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AiTutorWidget(questionText: 'Fixture', correctAnswer: 'a'),
            ),
          ),
        ),
      );
      await tester.tap(find.byType(TextButton));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      tutor.response.complete('Fixture explanation');
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  for (final language in ['uz', 'ru', 'en']) {
    testWidgets(
      'motivation screen fits landscape with large text ($language)',
      (tester) async {
        tester.view.physicalSize = const Size(640, 360);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await prefs.setString(PrefsKeys.language, language);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              prefsServiceProvider.overrideWithValue(prefs),
              authControllerProvider.overrideWith(LoggedOutTest.new),
            ],
            child: MaterialApp(
              theme: buildAppTheme(lightColors),
              home: const MediaQuery(
                data: MediaQueryData(
                  textScaler: TextScaler.linear(1.7),
                  disableAnimations: true,
                ),
                child: DuoOnboardingScreen(initialStep: 1),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('onboarding_continue_btn')).hitTestable(),
          findsOneWidget,
        );
      },
    );
  }
}
