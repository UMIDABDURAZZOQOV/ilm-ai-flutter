import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/api_contract.dart';
import '../../physics/data/physics_repository.dart' as physics;
import '../../chemistry/data/chemistry_repository.dart' as chemistry;
import '../../world_history/data/world_history_repository.dart' as world;
import '../../uzbekistan_history/data/history_repository.dart' as history;

typedef Json = Map<String, dynamic>;
List<Json> jsonRows(dynamic value) =>
    (value as List).map((v) => Map<String, dynamic>.from(v as Map)).toList();
final assessmentRepositoryProvider =
    Provider.family<AssessmentRepository, String>(
      (ref, slug) => AssessmentRepository(ref.watch(dioProvider), slug),
    );

/// One transport with the existing subject-specific public payload validators.
/// Scientific grading remains in the unchanged source-validated server engines.
class AssessmentRepository {
  final Dio dio;
  final String subject;
  late final Json Function(dynamic, String) _subjectChecked = switch (subject) {
    'fizika' => physics.PhysicsRepository(dio).checked,
    'kimyo' => chemistry.ChemistryRepository(dio).checked,
    'jahon_tarixi' => world.WorldHistoryRepository(dio).checked,
    'ozbekiston_tarixi' => history.HistoryRepository(dio).checked,
    _ => throw StateError('Subject has no v2 assessment engine'),
  };
  AssessmentRepository(this.dio, this.subject);
  Json _checked(dynamic value, String shape) {
    final result = _subjectChecked(value, shape);
    final completion = shape == 'result'
        ? result
        : shape == 'attempt'
        ? result['result']
        : null;
    if (completion != null &&
        (completion['stars'] is! int ||
            completion['elapsed_seconds'] is! int)) {
      throw const InvalidApiResponseException();
    }
    return result;
  }

  String get prefix => '/beta/v2/$subject';
  static String requestId() => physics.PhysicsRepository.requestId();
  static String storageKey(
    String origin,
    int uid,
    String subject,
    String key,
  ) =>
      'beta_v2:${sha256.convert(utf8.encode(origin)).toString().substring(0, 16)}:$uid:$subject:$key';
  Future<Json> catalog(CancelToken cancel, {required int grade}) async =>
      _checked(
        (await dio.get(
          '$prefix/catalog',
          queryParameters: {'grade': grade},
          cancelToken: cancel,
        )).data,
        'catalog',
      );
  Future<Json> start(String key, String request, CancelToken cancel) async =>
      _checked(
        (await dio.post(
          '$prefix/lessons/$key/start',
          data: {'assessment_version': 2, 'request_id': request},
          cancelToken: cancel,
        )).data,
        'attempt',
      );
  Future<Json> answer(
    String sid,
    String key,
    Json answer,
    CancelToken cancel,
  ) async => _checked(
    (await dio.post(
      '$prefix/attempts/$sid/answers',
      data: {'assessment_version': 2, 'assessment_key': key, 'answer': answer},
      cancelToken: cancel,
    )).data,
    'answer',
  );
  Future<Json> complete(String sid, CancelToken cancel) async => _checked(
    (await dio.post(
      '$prefix/attempts/$sid/complete',
      data: {'assessment_version': 2},
      cancelToken: cancel,
    )).data,
    'result',
  );
}
