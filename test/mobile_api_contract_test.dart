import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ilm_ai_flutter/core/network/api_contract.dart';
import 'package:ilm_ai_flutter/core/network/error_message.dart';
import 'package:ilm_ai_flutter/features/skills/data/skill_tree_repository.dart';
import 'release_hardening_test.dart' show Adapter, reply;

void main() {
  test('Google Future timeout has an actionable localized message', () {
    expect(
      extractError(TimeoutException('network'), language: 'uz'),
      contains('vaqti tugadi'),
    );
  });

  test(
    'malformed subject fields become a catalogue format error, not TypeError',
    () async {
      final dio = Dio()
        ..httpClientAdapter = Adapter(
          (_) => reply(200, [
            {'id': 'wrong-type', 'slug': 'biologiya'},
          ]),
        );
      addTearDown(() => dio.close(force: true));
      await expectLater(
        SkillTreeRepository(dio).getSubjects(),
        throwsA(isA<InvalidApiResponseException>()),
      );
    },
  );
}
