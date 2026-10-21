import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_contract.dart';
import '../../../core/network/dio_client.dart';

final physicsRepositoryProvider = Provider(
  (ref) => PhysicsRepository(ref.watch(dioProvider)),
);
typedef Json = Map<String, dynamic>;

List<Json> jsonRows(dynamic data) =>
    (data as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();

/// v2 is isolated from the MCQ repository: no client-side answer keys/score.
class PhysicsRepository {
  final Dio dio;
  const PhysicsRepository(this.dio);
  static const prefix = '/preview/physics/v2';

  Json checked(dynamic data, String shape) {
    if (data is! Map || data['assessment_version'] != 2) {
      throw const ApiCompatibilityException();
    }
    final payload = Map<String, dynamic>.from(data);
    try {
      void text(dynamic v) {
        if (v is! String || v.isEmpty) throw const FormatException();
      }

      void sources(dynamic refs) {
        for (final r in jsonRows(refs)) {
          text(r['topic_id']);
          if (r['pdf_pages'] is! List || r['printed_pages'] is! List) {
            throw const FormatException();
          }
        }
      }

      void result(Json r) {
        if (r['passed'] is! bool ||
            r['score'] is! num ||
            r['total'] is! int ||
            r['xp_awarded'] is! int ||
            r['streak_days'] is! int) {
          throw const FormatException();
        }
      }

      if (shape == 'catalog') {
        for (final row in jsonRows(payload['lessons'])) {
          text(row['key']);
          text(row['title']);
          sources(row['source_refs']);
          if (row['sequence'] is! int ||
              !{'locked', 'available', 'completed'}.contains(row['state'])) {
            throw const FormatException();
          }
        }
      } else if (shape == 'attempt') {
        text(payload['attempt_id']);
        text(payload['title']);
        final content = payload['content'] as Json;
        for (final field in ['cards', 'formulas', 'examples']) {
          for (final item in jsonRows(content[field])) {
            text(item['title']);
            text(item['body']);
            sources(item['source_refs']);
            if (field == 'examples') {
              for (final step in jsonRows(item['steps'])) {
                text(step['body']);
              }
            }
          }
        }
        final questions = jsonRows(payload['questions']);
        if (questions.isEmpty ||
            questions.length > 50 ||
            payload['answers'] is! Map) {
          throw const FormatException();
        }
        for (final q in questions) {
          text(q['key']);
          text(q['prompt']);
          sources(q['source_refs']);
          if (q['response_kind'] == 'numeric_quantity') {
            for (final g in jsonRows(q['givens'])) {
              text(g['symbol']);
              text(g['value']);
              text(g['unit']);
            }
            List<String>.from(q['symbols'] as List);
          } else if ({
            'concept_selection',
            'ordering',
          }.contains(q['response_kind'])) {
            for (final item in jsonRows(
              q[q['response_kind'] == 'ordering' ? 'items' : 'options'],
            )) {
              text(item['id']);
              text(item['label']);
            }
          } else {
            throw const FormatException();
          }
        }
        if (payload['result'] != null) result(payload['result'] as Json);
      } else if (shape == 'answer') {
        text(payload['feedback']);
        sources(payload['source_refs']);
        if (payload['is_correct'] is! bool) throw const FormatException();
        for (final step in jsonRows(payload['solution'])) {
          text(step['body']);
        }
      } else {
        result(payload);
      }
    } on TypeError {
      throw const InvalidApiResponseException();
    } on FormatException {
      throw const InvalidApiResponseException();
    }
    return payload;
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
