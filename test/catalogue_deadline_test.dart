import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  testWidgets('stalled interceptor cannot prevent the whole-request deadline', (
    tester,
  ) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://isolated.example.test'))
      ..interceptors.add(InterceptorsWrapper(onRequest: (_, _) {}));
    addTearDown(() => dio.close(force: true));
    Object? failure;
    unawaited(
      SkillTreeRepository(dio).getSubjects().then<void>(
        (_) {},
        onError: (Object error) {
          failure = error;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(failure, isA<TimeoutException>());
  });
  testWidgets('stalled catalogue reaches timeout and a new request can retry', (
    tester,
  ) async {
    final pending = Completer<ResponseBody>();
    var calls = 0;
    final dio = Dio(BaseOptions(baseUrl: 'https://isolated.example.test'))
      ..httpClientAdapter = Adapter((request) {
        calls++;
        expectSync(request.extra['skipAuth'], isTrue);
        return calls == 1 ? pending.future : reply(200, []);
      });
    addTearDown(() => dio.close(force: true));
    final repository = SkillTreeRepository(dio);
    Object? failure;
    unawaited(
      repository.getSubjects().then<void>(
        (_) {},
        onError: (Object error) {
          failure = error;
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 31));
    expect(failure, isA<TimeoutException>());
    expect(calls, 1);
    await tester.runAsync(() async {
      expect(await repository.getSubjects(), isEmpty);
    });
    expect(calls, 2);
    pending.complete(reply(200, []));
    await tester.pump();
  });
  testWidgets('completed catalogue cancels its deadline timer', (tester) async {
    final dio = Dio(BaseOptions(baseUrl: 'https://isolated.example.test'))
      ..httpClientAdapter = Adapter((_) => reply(200, []));
    addTearDown(() => dio.close(force: true));
    await tester.runAsync(() async {
      expect(await SkillTreeRepository(dio).getSubjects(), isEmpty);
    });
    await tester.pump(const Duration(seconds: 31));
    expect(tester.takeException(), isNull);
  });
}
