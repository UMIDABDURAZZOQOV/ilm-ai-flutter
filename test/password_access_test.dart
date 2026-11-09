import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/theme/app_theme.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_models.dart';
import 'package:ilm_ai_flutter/features/auth/data/auth_repository.dart';
import 'package:ilm_ai_flutter/features/auth/presentation/password_access_sheet.dart';
import 'release_hardening_test.dart' show Adapter, reply;

const owner = AuthResponse(
  accessToken: 'synthetic-owner-access',
  refreshToken: 'synthetic-owner-refresh',
  userId: 42,
  name: 'Learner',
  email: 'learner@example.test',
);

Dio network(Future<ResponseBody> Function(RequestOptions) handler) =>
    Dio(BaseOptions(baseUrl: 'https://isolated.example.test'))
      ..httpClientAdapter = Adapter(handler);

Future<void> mount(WidgetTester tester, Dio dio) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(lightColors),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<PasswordAccessResult>(
              context: context,
              isScrollControlled: true,
              isDismissible: false,
              enableDrag: false,
              builder: (_) => PasswordAccessSheet(
                repository: AuthRepository(dio),
                language: 'en',
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Future<void> fill(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const ValueKey('password_email')),
    owner.email,
  );
  await tester.enterText(
    find.byKey(const ValueKey('password_secret')),
    'synthetic-password',
  );
}

Future<void> submit(WidgetTester tester) async {
  final button = find.byKey(const ValueKey('password_continue'));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pump();
}

void main() {
  test('email-free signup preserves authenticated owner and tokens', () async {
    final dio = network((request) async {
      expect(request.path, '/auth/signup');
      expect(request.extra['skipAuth'], isTrue);
      return reply(200, {...owner.toJson(), 'verification_required': false});
    });
    addTearDown(() => dio.close(force: true));
    final result = await AuthRepository(dio).registerPassword(
      const SignUpRequest(
        name: 'Learner',
        email: 'learner@example.test',
        password: 'synthetic-password',
      ),
    );
    expect(result.authentication, owner);
    expect(result.verificationEmail, isNull);
  });
  test(
    'legacy signup requiring delivery remains explicit, never authenticated',
    () async {
      final dio = network(
        (_) async =>
            reply(200, {'verification_required': true, 'email': owner.email}),
      );
      addTearDown(() => dio.close(force: true));
      final result = await AuthRepository(dio).registerPassword(
        const SignUpRequest(
          name: 'Learner',
          email: 'learner@example.test',
          password: 'synthetic-password',
        ),
      );
      expect(result.authentication, isNull);
      expect(result.verificationEmail, owner.email);
    },
  );
  for (final invalid in [null, 'false', 0]) {
    test('signup rejects malformed verification flag $invalid', () async {
      final dio = network(
        (_) async =>
            reply(200, {...owner.toJson(), 'verification_required': invalid}),
      );
      addTearDown(() => dio.close(force: true));
      await expectLater(
        AuthRepository(dio).registerPassword(
          const SignUpRequest(
            name: 'Learner',
            email: 'learner@example.test',
            password: 'synthetic-password',
          ),
        ),
        throwsException,
      );
    });
  }
  for (final setup in [true, false]) {
    test('owner profile uses only newly issued bearer, setup=$setup', () async {
      final dio = network((request) async {
        expect(request.path, '/auth/profile/42');
        expect(request.headers['Authorization'], 'Bearer ${owner.accessToken}');
        expect(request.extra['skipAuth'], isTrue);
        expect(request.extra['skipAuthRefresh'], isTrue);
        return reply(200, {'needs_onboarding': setup});
      });
      addTearDown(() => dio.close(force: true));
      expect(await AuthRepository(dio).passwordNeedsOnboarding(owner), setup);
    });
  }
  test('malformed profile cannot bypass onboarding', () async {
    final dio = network((_) async => reply(200, {'needs_onboarding': 'false'}));
    addTearDown(() => dio.close(force: true));
    await expectLater(
      AuthRepository(dio).passwordNeedsOnboarding(owner),
      throwsException,
    );
  });
  testWidgets('cancel exits without a network call or session', (tester) async {
    final dio = network((_) async => throw StateError('Unexpected request'));
    addTearDown(() => dio.close(force: true));
    await mount(tester, dio);
    await tester.ensureVisible(find.byKey(const ValueKey('password_cancel')));
    await tester.tap(find.byKey(const ValueKey('password_cancel')));
    await tester.pumpAndSettle();
    expect(find.byType(PasswordAccessSheet), findsNothing);
  });
  testWidgets('invalid fields do not request credentials from server', (
    tester,
  ) async {
    final dio = network((_) async => throw StateError('Unexpected request'));
    addTearDown(() => dio.close(force: true));
    await mount(tester, dio);
    await submit(tester);
    expect(find.text('Check your email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed existing login never creates an account', (tester) async {
    final calls = <String>[];
    final dio = network((request) async {
      calls.add(request.path);
      return reply(401, {'detail': 'Invalid credentials'});
    });
    addTearDown(() => dio.close(force: true));
    await mount(tester, dio);
    await fill(tester);
    await submit(tester);
    await tester.pumpAndSettle();
    expect(calls, ['/auth/login']);
    expect(find.byType(PasswordAccessSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'duplicate submit and dismissal are disabled while authenticating',
    (tester) async {
      final pending = Completer<void>();
      var attempts = 0;
      final dio = network((request) async {
        attempts++;
        await pending.future;
        return reply(401, {'detail': 'Invalid credentials'});
      });
      addTearDown(() => dio.close(force: true));
      await mount(tester, dio);
      await fill(tester);
      await submit(tester);
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('password_continue')),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<TextButton>(find.byKey(const ValueKey('password_cancel')))
            .onPressed,
        isNull,
      );
      expect(attempts, 1);
      pending.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unconfigured recovery never claims that email was sent', (
    tester,
  ) async {
    final dio = network((request) async {
      expect(request.path, '/auth/password-reset/request');
      return reply(503, {
        'detail': 'secure_password_recovery_requires_delivery_service',
      });
    });
    addTearDown(() => dio.close(force: true));
    await mount(tester, dio);
    await fill(tester);
    await tester.ensureVisible(find.text('Recover password'));
    await tester.tap(find.text('Recover password'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Secure password recovery is not configured yet. Contact support.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('password_email_code')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
