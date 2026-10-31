import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ilm_ai_flutter/core/network/dio_client.dart';
import 'package:ilm_ai_flutter/core/providers/app_providers.dart';
import 'package:ilm_ai_flutter/core/storage/prefs_service.dart';
import 'package:ilm_ai_flutter/core/storage/secure_token_storage.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/application/auth_controller.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/skills/application/learning_preferences.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'package:ilm_ai_flutter/features/study_help/study_help.dart';
import 'biology_curriculum_test.dart' show fixture;
import 'release_hardening_test.dart' show Adapter, reply, original;
import 'study_help_test.dart' show DeferredHelp, evidence;

class CountingSecureStorage extends FlutterSecureStorage {
  int reads = 0;
  bool failWrite = false, failRead = false;
  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    if (failRead) throw StateError('test read failure');
    return super.read(key: key);
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (failWrite) throw StateError('test write failure');
    await super.write(key: key, value: value);
  }
}

class DelayedProfile extends AuthRepository {
  DelayedProfile() : super(Dio());
  bool started = false;
  final response = Completer<bool>();
  @override
  Future<bool> needsOnboarding(int userId) {
    started = true;
    return response.future;
  }
}

class DelayedPreferences extends LearningPreferences {
  DelayedPreferences(super.dio, super.prefs);
  int calls = 0;
  Completer<void>? hold = Completer<void>();
  @override
  Future<void> restore(int id) {
    calls++;
    return hold?.future ?? Future.value();
  }
}

class ClockAuth extends AuthController {
  DateTime currentTime = DateTime(2026, 10, 31);
  @override
  DateTime get now => currentTime;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'ilm_tokens': jsonEncode(original.toJson()),
    });
    SharedPreferences.setMockInitialValues({});
  });

  test('64 parallel auth reads hydrate secure storage once', () async {
    final native = CountingSecureStorage();
    final storage = SecureTokenStorage(native);
    addTearDown(storage.dispose);
    final tokens = await Future.wait(
      List.generate(64, (_) => storage.getTokens()),
    );
    expect(native.reads, 1);
    expect(tokens.every((t) => t!.userId == original.userId), true);
    await storage.replaceRefresh(original.refreshToken, 'fresh', 'rotated');
    expect((await storage.getTokens())!.refreshToken, 'rotated');
    await storage.clearTokens();
    expect(await storage.getTokens(), isNull);
    expect(native.reads, 1);
  });

  test('failed secure writes do not replace cached authority', () async {
    final native = CountingSecureStorage();
    final storage = SecureTokenStorage(native);
    addTearDown(storage.dispose);
    await storage.getTokens();
    native.failWrite = true;
    await expectLater(
      storage.saveTokens(original.copyWith(name: 'unsaved')),
      throwsStateError,
    );
    expect((await storage.getTokens())!.name, original.name);
    native.failWrite = false;
    await storage.updateTokens((t) => t.copyWith(name: 'saved'));
    expect((await storage.getTokens())!.name, 'saved');
  });

  test('failed secure hydration can be retried', () async {
    final native = CountingSecureStorage()..failRead = true;
    final storage = SecureTokenStorage(native);
    addTearDown(storage.dispose);
    await expectLater(storage.getTokens(), throwsStateError);
    native.failRead = false;
    expect((await storage.getTokens())!.userId, original.userId);
    expect(native.reads, 2);
  });

  test(
    'tree coalescing never crosses account, grade, or progress revision',
    () async {
      final dio = Dio();
      final requests = <RequestOptions>[];
      final response = Completer<void>();
      final dispatched = Completer<void>();
      dio.httpClientAdapter = Adapter((r) async {
        requests.add(r);
        if (requests.length == 4) dispatched.complete();
        await response.future;
        return reply(200, fixture('biology_grade5_tree'));
      });
      addTearDown(dio.close);
      final repo = SkillTreeRepository(dio);
      final calls = [
        repo.getTree(
          userId: 1,
          subjectSlug: 'biologiya',
          grade: 5,
          revision: 1,
        ),
        repo.getTree(
          userId: 1,
          subjectSlug: 'biologiya',
          grade: 5,
          revision: 1,
        ),
        repo.getTree(
          userId: 1,
          subjectSlug: 'biologiya',
          grade: 5,
          revision: 2,
        ),
        repo.getTree(
          userId: 2,
          subjectSlug: 'biologiya',
          grade: 5,
          revision: 1,
        ),
        repo.getTree(
          userId: 1,
          subjectSlug: 'biologiya',
          grade: 6,
          revision: 1,
        ),
      ];
      await dispatched.future;
      expect(requests.length, 4);
      response.complete();
      await Future.wait(calls);
      await repo.getTree(
        userId: 1,
        subjectSlug: 'biologiya',
        grade: 5,
        revision: 1,
      );
      expect(requests.length, 5); // No stale successful-result cache.
    },
  );

  test(
    'failed coalesced tree request is removed and retries normally',
    () async {
      final dio = Dio();
      int count = 0;
      dio.httpClientAdapter = Adapter((r) {
        count++;
        return count == 1
            ? reply(503, {})
            : reply(200, fixture('biology_grade5_tree'));
      });
      addTearDown(dio.close);
      final repo = SkillTreeRepository(dio);
      await expectLater(
        repo.getTree(
          userId: 1,
          subjectSlug: 'biologiya',
          grade: 5,
          revision: 1,
        ),
        throwsA(isA<DioException>()),
      );
      await repo.getTree(
        userId: 1,
        subjectSlug: 'biologiya',
        grade: 5,
        revision: 1,
      );
      expect(count, 2);
    },
  );

  test(
    'preferences restore coalesces and cannot overwrite a newer flushed edit',
    () async {
      final prefs = await PrefsService.create();
      final dio = Dio();
      final remote = Completer<ResponseBody>();
      final dispatched = Completer<void>();
      int reads = 0;
      dio.httpClientAdapter = Adapter((r) {
        if (r.method == 'GET') {
          reads++;
          dispatched.complete();
          return remote.future;
        }
        return reply(200, {'ok': true});
      });
      addTearDown(dio.close);
      final preferences = LearningPreferences(dio, prefs);
      final a = preferences.restore(1), b = preferences.restore(1);
      await dispatched.future;
      expect(reads, 1);
      await preferences.save(1, {'grade': '7'});
      await preferences.flush(1);
      remote.complete(
        reply(200, {
          'preferences': {'grade': '5'},
        }),
      );
      await Future.wait([a, b]);
      expect(prefs.getString('class_1'), '7');
    },
  );

  test(
    'startup profile/preferences reads overlap; brief/concurrent resumes do not reload',
    () async {
      final prefs = await PrefsService.create();
      final storage = SecureTokenStorage(CountingSecureStorage());
      addTearDown(storage.dispose);
      final profile = DelayedProfile();
      final preferences = DelayedPreferences(Dio(), prefs);
      final container = ProviderContainer(
        overrides: [
          prefsServiceProvider.overrideWithValue(prefs),
          secureTokenStorageProvider.overrideWithValue(storage),
          authRepositoryProvider.overrideWithValue(profile),
          learningPreferencesProvider.overrideWithValue(preferences),
          authControllerProvider.overrideWith(ClockAuth.new),
        ],
      );
      addTearDown(container.dispose);
      final restored = container.read(authControllerProvider.future);
      await Future<void>.delayed(Duration.zero);
      expect(profile.started, true);
      expect(preferences.calls, 1);
      profile.response.complete(false);
      preferences.hold!.complete();
      await restored;
      final auth = container.read(authControllerProvider.notifier) as ClockAuth;
      final revision = container.read(studyRevisionProvider);
      await Future.wait(List.generate(20, (_) => auth.resume()));
      expect(preferences.calls, 1);
      expect(container.read(studyRevisionProvider), revision);
      auth.currentTime = auth.currentTime.add(const Duration(seconds: 31));
      preferences.hold = Completer<void>();
      final a = auth.resume(), b = auth.resume();
      expect(preferences.calls, 2);
      preferences.hold!.complete();
      await Future.wait([a, b]);
      expect(container.read(studyRevisionProvider), revision + 1);
      await prefs.setBool('study_preferences_dirty_1', true);
      preferences.hold = null;
      await auth.resume();
      expect(
        preferences.calls,
        3,
      ); // Unsynced edits bypass the freshness window.
    },
  );

  testWidgets('rapid help taps open one modal and one request', (tester) async {
    final dio = Dio();
    final repository = DeferredHelp(dio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWithValue(1),
          studyHelpRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: buildAppTheme(lightColors),
          home: const Scaffold(
            body: StudyHelpButton(
              contextData: StudyHelpContext(
                subject: 'kimyo',
                grade: 7,
                attemptId: 'owned',
                questionKey: 'q',
                checked: true,
              ),
              language: 'uz',
            ),
          ),
        ),
      ),
    );
    final button = tester.widget<TextButton>(
      find.byKey(const ValueKey('question_study_help')),
    );
    for (var i = 0; i < 10; i++) {
      button.onPressed!();
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StudyHelpSheet), findsOneWidget);
    expect(repository.cancellation, isNotNull);
    repository.result.complete(evidence());
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();
    expect(find.byType(StudyHelpSheet), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    dio.close();
  });
}
