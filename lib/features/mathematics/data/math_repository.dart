import 'dart:math';
import 'package:dio/dio.dart';

typedef MathJson = Map<String, dynamic>;
List<MathJson> mathRows(dynamic value) =>
    (value as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();

String mathRequestId() {
  final random = Random.secure();
  final bytes = List.generate(16, (_) => random.nextInt(256));
  bytes[6] = (bytes[6] & 15) | 64;
  bytes[8] = (bytes[8] & 63) | 128;
  final hex = bytes.map((v) => v.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// Public DTOs only; the client never computes correctness or XP.
class MathRepository {
  final Dio dio;
  const MathRepository(this.dio);
  static const prefix = '/preview/mathematics/v1';
  Options get options => Options(
    sendTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  );

  MathJson checked(dynamic value, String type) {
    if (value is! Map || value['assessment_version'] != 1) {
      throw const FormatException('Matematika API versiyasi mos emas.');
    }
    final result = Map<String, dynamic>.from(value);
    try {
      void text(dynamic v) {
        if (v is! String || v.isEmpty) throw const FormatException();
      }

      if (type == 'catalog') {
        if (result['subject'] != 'mathematics') throw const FormatException();
        for (final lesson in mathRows(result['lessons'])) {
          text(lesson['key']);
          text(lesson['title']);
          if (!(lesson['key'] as String).startsWith('math-') ||
              !{'locked', 'available', 'completed'}.contains(lesson['state'])) {
            throw const FormatException();
          }
        }
      } else if (type == 'attempt') {
        text(result['attempt_id']);
        text(result['title']);
        if (!(result['lesson_key'] as String).startsWith('math-') ||
            result['answers'] is! List) {
          throw const FormatException();
        }
        final content = result['content'] as Map;
        for (final card in mathRows(content['cards'])) {
          text(card['title']);
          text(card['body']);
        }
        for (final example in mathRows(content['examples'])) {
          text(example['title']);
          for (final step in mathRows(example['steps'])) {
            text(step['action']);
            text(step['why']);
          }
        }
        final questions = mathRows(result['questions']);
        if (questions.isEmpty || questions.length > 50) {
          throw const FormatException();
        }
        for (final q in questions) {
          text(q['id']);
          text(q['prompt']);
          if (!{
            'choice',
            'short_text',
            'exact_number',
          }.contains(q['response_kind'])) {
            throw const FormatException();
          }
          if (q['response_kind'] == 'choice' &&
              mathRows(q['choices']).isEmpty) {
            throw const FormatException();
          }
          if (q['visual'] != null) {
            final scene = q['visual'] as Map;
            if (!{'shape_board', 'bars'}.contains(scene['type'])) {
              throw const FormatException();
            }
            final items = mathRows(scene['items']);
            if (items.isEmpty || items.length > 9) {
              throw const FormatException();
            }
            for (final item in items) {
              text(item['id']);
              if (!{
                    'circle',
                    'square',
                    'triangle',
                    'rectangle',
                    'sphere',
                    'cube',
                  }.contains(item['shape']) ||
                  !{'indigo', 'yellow', 'turquoise'}.contains(item['color'])) {
                throw const FormatException();
              }
              for (final coordinate in ['x', 'y', 'size']) {
                final v = item[coordinate];
                if (v is! num ||
                    !v.isFinite ||
                    v < (coordinate == 'size' ? .4 : .1) ||
                    v > (coordinate == 'size' ? 1.4 : .9)) {
                  throw const FormatException();
                }
              }
            }
          }
        }
      } else if (type == 'answer') {
        text(result['feedback']);
        text(result['question_id']);
        if (result['is_correct'] is! bool || result['request_id'] is! String) {
          throw const FormatException();
        }
      } else if (result['xp_awarded'] is! int || result['passed'] is! bool) {
        throw const FormatException();
      }
    } on TypeError {
      throw const FormatException('Matematika API javobi mos emas.');
    }
    return result;
  }

  Future<MathJson> catalog(CancelToken cancel) async => checked(
    (await dio.get(
      '$prefix/catalog',
      options: options,
      cancelToken: cancel,
    )).data,
    'catalog',
  );
  Future<MathJson> start(
    String key,
    String request,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/lessons/$key/start',
      data: {'assessment_version': 1, 'request_id': request},
      options: options,
      cancelToken: cancel,
    )).data,
    'attempt',
  );
  Future<MathJson> answer(
    String attempt,
    MathJson submission,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/attempts/$attempt/answers',
      data: {'assessment_version': 1, ...submission},
      options: options,
      cancelToken: cancel,
    )).data,
    'answer',
  );
  Future<MathJson> complete(
    String attempt,
    String request,
    CancelToken cancel,
  ) async => checked(
    (await dio.post(
      '$prefix/attempts/$attempt/complete',
      data: {'assessment_version': 1, 'request_id': request},
      options: options,
      cancelToken: cancel,
    )).data,
    'result',
  );
}
