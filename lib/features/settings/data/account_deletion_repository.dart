import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class DeletionProof {
  const DeletionProof(this.requestId, this.proof);
  final String requestId, proof;
  factory DeletionProof.parse(dynamic data) {
    if (data is! Map ||
        data['request_id'] is! String ||
        !RegExp(r'^da[pw]_[A-Za-z0-9_-]{39}$').hasMatch(data['request_id']) ||
        data['proof'] is! String ||
        !RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(data['proof']) ||
        data['expires_in_seconds'] != 300) {
      throw const FormatException('Invalid deletion authorization');
    }
    return DeletionProof(data['request_id'], data['proof']);
  }
}

class AccountDeletionRepository {
  const AccountDeletionRepository(this.dio);
  final Dio dio;

  Future<Map<String, dynamic>> configuration(CancelToken cancel) async {
    final response = await dio.get(
      '/account/deletion/config',
      cancelToken: cancel,
    );
    if (response.data is! Map || response.data['available'] is! bool) {
      throw const FormatException('Invalid deletion configuration');
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<String> method(CancelToken cancel) async {
    final response = await dio.get(
      '/account/deletion/reauth/options',
      cancelToken: cancel,
    );
    if (response.data is! Map ||
        !['google', 'password'].contains(response.data['method'])) {
      throw const FormatException('Invalid reauthentication method');
    }
    return response.data['method'] as String;
  }

  Future<DeletionProof> passwordProof(
    String password,
    CancelToken cancel,
  ) async => DeletionProof.parse(
    (await dio.post(
      '/account/deletion/reauth/password',
      data: {'password': password},
      cancelToken: cancel,
    )).data,
  );

  Future<Map<String, dynamic>> prepareGoogle(
    String challenge,
    CancelToken cancel,
  ) async {
    final response = await dio.post(
      '/account/deletion/reauth/google',
      data: {'code_challenge': challenge},
      cancelToken: cancel,
    );
    if (response.data is! Map ||
        response.data['auth_url'] is! String ||
        response.data['state'] is! String) {
      throw const FormatException('Invalid Google reauthentication response');
    }
    return Map<String, dynamic>.from(response.data);
  }

  Future<DeletionProof> exchangeProof(
    String code,
    String verifier,
    CancelToken cancel,
  ) async => DeletionProof.parse(
    (await dio.post(
      '/account/deletion/reauth/exchange',
      data: {'code': code, 'code_verifier': verifier},
      cancelToken: cancel,
    )).data,
  );

  Future<String> confirmProof(DeletionProof proof, CancelToken cancel) async {
    final response = await dio.post(
      '/account/deletion/reauth/confirm',
      data: {
        'request_id': proof.requestId,
        'proof': proof.proof,
        'confirmation': 'DELETE',
      },
      cancelToken: cancel,
      options: Options(
        extra: {'skipAuthRefresh': true},
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    return _receipt(response.data);
  }

  String _receipt(dynamic value) {
    if (value is! Map ||
        !{
          'deleted',
          'pending_cleanup',
          'retention_review',
        }.contains(value['state']) ||
        value['account_revoked'] != (value['state'] != 'retention_review')) {
      throw const FormatException('Invalid deletion acknowledgement');
    }
    return value['state'] as String;
  }

  Future<String> request(CancelToken cancel) async {
    final response = await dio.post(
      '/account/deletion/me/request',
      cancelToken: cancel,
      options: Options(receiveTimeout: const Duration(seconds: 60)),
    );
    final value = response.data;
    if (value is! Map ||
        value['request_id'] is! String ||
        !RegExp(
          r'^[A-Za-z0-9_-]{43}$',
        ).hasMatch(value['request_id'] as String)) {
      throw const FormatException('Invalid deletion challenge');
    }
    return value['request_id'] as String;
  }

  Future<String> confirm(
    String requestId,
    String code,
    CancelToken cancel,
  ) async {
    final response = await dio.post(
      '/account/deletion/confirm',
      cancelToken: cancel,
      data: {'request_id': requestId, 'code': code, 'confirmation': 'DELETE'},
      // The OTP proof is sufficient for a retry even if the first response was
      // lost after server revocation. Never trigger a token refresh on this call.
      options: Options(
        extra: {'skipAuth': true},
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    final value = response.data;
    if (value is! Map ||
        !{
          'deleted',
          'pending_cleanup',
          'retention_review',
        }.contains(value['state']) ||
        value['account_revoked'] != (value['state'] != 'retention_review')) {
      throw const FormatException('Invalid deletion acknowledgement');
    }
    return value['state'] as String;
  }
}

final accountDeletionRepositoryProvider = Provider(
  (ref) => AccountDeletionRepository(ref.watch(dioProvider)),
);
