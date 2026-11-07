import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AccountDeletionRepository {
  const AccountDeletionRepository(this.dio);
  final Dio dio;

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
