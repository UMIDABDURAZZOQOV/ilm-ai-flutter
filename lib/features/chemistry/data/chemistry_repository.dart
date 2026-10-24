import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_contract.dart';
import '../../../core/network/dio_client.dart';

typedef Json = Map<String, dynamic>;
List<Json> jsonRows(dynamic data) =>
    (data as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();

final chemistryRepositoryProvider = Provider(
  (ref) => ChemistryRepository(ref.watch(dioProvider)),
);

/// Same versioned local assessment contract as Physics; no client grading keys.
class ChemistryRepository {
  final Dio dio;
  const ChemistryRepository(this.dio);
  static const prefix = '/preview/chemistry/v2';

  Json checked(dynamic data, String shape) {
    if (data is! Map || data['assessment_version'] != 2) {
      throw const ApiCompatibilityException();
    }
    try {
      final payload = Map<String, dynamic>.from(data);
      void text(dynamic value) {
        if (value is! String || value.isEmpty) throw const FormatException();
      }

      void refs(dynamic values) {
        final rows = jsonRows(values);
        if (rows.isEmpty) throw const FormatException();
        for (final r in rows) {
          text(r['topic_id']);
          text(r['sha256']);
          final printed = List<int>.from(r['printed_pages'] as List);
          final pdf = List<int>.from(r['pdf_pages'] as List);
          final regions = List<String>.from(r['regions'] as List);
          if (printed.isEmpty ||
              pdf.length != printed.length ||
              regions.length != printed.length ||
              regions.any((v) => !{'left', 'right', 'full'}.contains(v))) {
            throw const FormatException();
          }
        }
      }

      void privateKeys(dynamic value) {
        if (value is Map) {
          if (value.keys.any(
            {
              'expected',
              'grading_spec',
              'aliases',
              'choice_ids',
              'verified_answer',
              'correct_answer',
              'facts',
            }.contains,
          )) {
            throw const FormatException();
          }
          for (final child in value.values) {
            privateKeys(child);
          }
        } else if (value is List) {
          for (final child in value) {
            privateKeys(child);
          }
        }
      }

      void result(Json r) {
        if (r['passed'] is! bool ||
            r['score'] is! int ||
            r['total'] is! int ||
            r['xp_awarded'] is! int ||
            r['streak_days'] is! int ||
            r['stars'] is! int ||
            r['elapsed_seconds'] is! int) {
          throw const FormatException();
        }
      }

      if (shape == 'catalog') {
        if (payload['subject'] != 'kimyo' ||
            payload['grade'] is! int ||
            payload['source_sections'] is! int) {
          throw const FormatException();
        }
        for (final row in jsonRows(payload['lessons'])) {
          text(row['key']);
          text(row['title']);
          refs(row['source_refs']);
          if (row['sequence'] is! int ||
              !{'available', 'locked', 'completed'}.contains(row['state'])) {
            throw const FormatException();
          }
        }
      } else if (shape == 'attempt') {
        text(payload['attempt_id']);
        text(payload['title']);
        text(payload['lesson_key']);
        DateTime.parse(payload['expires_at'] as String);
        final content = Map<String, dynamic>.from(payload['content'] as Map);
        privateKeys(content);
        final cards = jsonRows(content['cards']);
        if (cards.isEmpty || cards.length > 50) throw const FormatException();
        for (final card in cards) {
          text(card['title']);
          text(card['body']);
          refs(card['source_refs']);
        }
        final questions = jsonRows(payload['questions']);
        if (questions.isEmpty ||
            questions.length > 50 ||
            payload['answers'] is! Map) {
          throw const FormatException();
        }
        privateKeys(questions);
        for (final q in questions) {
          text(q['key']);
          text(q['prompt']);
          refs(q['source_refs']);
          if (q['response_kind'] == 'concept_selection') {
            final options = jsonRows(q['options']);
            if (options.length != 4 ||
                options.map((o) => o['id']).toSet().length != 4) {
              throw const FormatException();
            }
            for (final option in options) {
              text(option['id']);
              text(option['label']);
            }
          } else if ({
            'short_text',
            'numeric_value',
          }.contains(q['response_kind'])) {
            if (q['max_length'] != 80) throw const FormatException();
            text(q['input_label']);
            if (q['response_kind'] == 'numeric_value' && q['unit'] is! String) {
              throw const FormatException();
            }
          } else {
            throw const FormatException();
          }
        }
        if (payload['result'] != null) {
          result(Map<String, dynamic>.from(payload['result'] as Map));
        }
      } else if (shape == 'answer') {
        if (payload['is_correct'] is! bool) throw const FormatException();
        text(payload['feedback']);
        text(payload['correct_answer']);
        refs(payload['source_refs']);
        for (final step in jsonRows(payload['solution'])) {
          text(step['body']);
          refs(step['source_refs']);
        }
      } else {
        result(payload);
      }
      return payload;
    } on TypeError {
      throw const InvalidApiResponseException();
    } on FormatException {
      throw const InvalidApiResponseException();
    }
  }

  Options get options => Options(
    sendTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 25),
  );
  Future<Json> catalog(CancelToken cancel) async => checked(
    (await dio.get(
      '$prefix/catalog',
      options: options,
      cancelToken: cancel,
    )).data,
    'catalog',
  );
  Future<Json> start(String key, String requestId, CancelToken cancel) async =>
      checked(
        (await dio.post(
          '$prefix/lessons/${Uri.encodeComponent(key)}/start',
          data: {'assessment_version': 2, 'request_id': requestId},
          options: options,
          cancelToken: cancel,
        )).data,
        'attempt',
      );
  Future<Json> answer(
    String attemptId,
    String key,
    Json answer,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/attempts/${Uri.encodeComponent(attemptId)}/answers',
      data: {'assessment_version': 2, 'assessment_key': key, 'answer': answer},
      options: options,
      cancelToken: cancel,
    )).data,
    'answer',
  );
  Future<Json> complete(String attemptId, CancelToken cancel) async => checked(
    (await dio.post(
      '$prefix/attempts/${Uri.encodeComponent(attemptId)}/complete',
      data: {'assessment_version': 2},
      options: options,
      cancelToken: cancel,
    )).data,
    'result',
  );
  static String requestId() {
    final random = Random.secure();
    final bytes = List.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((n) => n.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
