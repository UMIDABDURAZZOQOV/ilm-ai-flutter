import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilm_ai_flutter/core/config/phone_qa.dart';
import 'package:ilm_ai_flutter/features/phone_qa/phone_qa_hub.dart';

void main() {
  testWidgets('QA hub shows all subjects without overflow at large text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(overrides: [
      phoneQaSummaryProvider.overrideWith((ref) async => {
        'name': 'Telefon QA', 'xp_total': 0, 'streak_days': 0,
      }),
    ], child: MaterialApp(builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(2)),
      child: child!), home: const PhoneQaHub())));
    await tester.pumpAndSettle();
    expect(find.text('ILM AI QA'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Jahon tarixi'), 300);
    expect(find.text('Jahon tarixi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  test('QA API is exactly the designated USB loopback origin', () {
    expect(isPhoneQaUrl('http://127.0.0.1:8925'), isTrue);
    for (final url in [
      'https://ilm-ai-backend-256x.onrender.com',
      'http://192.168.1.2:8925',
      'http://localhost:8925',
      'http://127.0.0.1:8000',
      'http://user@127.0.0.1:8925',
      'http://127.0.0.1:8925/path',
      'http://127.0.0.1:8925?token=x',
      'http://127.0.0.1:8925#x',
    ]) {
      expect(isPhoneQaUrl(url), isFalse, reason: url);
    }
    expect(isPhoneQaRequest(Uri.parse('http://127.0.0.1:8925/qa/me')), isTrue);
    expect(
      isPhoneQaRequest(Uri.parse('https://example.com/auth/refresh')),
      isFalse,
    );
  });
  test('five existing adapters, with honest lesson counts', () {
    expect(PhoneQaHub.subjects.map((s) => s.title), [
      'Biologiya',
      'Fizika',
      'Kimyo',
      'O‘zbekiston tarixi',
      'Jahon tarixi',
    ]);
    expect(PhoneQaHub.subjects.fold(0, (n, s) => n + s.count), 1381);
  });
  test('normal entry cannot silently turn into phone QA', () {
    if (!phoneQaRequested) {
      expect(phoneQaEnabled, isFalse);
      expect(
        () => requirePhoneQaConfiguration('http://127.0.0.1:8925'),
        throwsStateError,
      );
    }
    expect(
      () => requirePhoneQaConfiguration('https://example.com'),
      throwsStateError,
    );
  });
}
