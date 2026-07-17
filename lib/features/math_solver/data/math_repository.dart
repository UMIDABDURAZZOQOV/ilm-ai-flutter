import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'math_models.dart';

class MathRepository {
  final Dio _dio;
  const MathRepository(this._dio);

  Future<MathSolveResult> solveText({required int userId, required String problem, required String language}) async {
    final res = await _dio.post('/math/solve-text', data: {'user_id': userId, 'problem': problem, 'language': language});
    return MathSolveResult.fromJson(res.data as Map<String, dynamic>);
  }

  Future<MathSolveResult> solveImage({required int userId, required String language, required String imagePath}) async {
    final formData = FormData.fromMap({
      'user_id': userId,
      'language': language,
      'image': await MultipartFile.fromFile(imagePath, filename: 'problem.jpg'),
    });
    final res = await _dio.post('/math/solve-image', data: formData);
    return MathSolveResult.fromJson(res.data as Map<String, dynamic>);
  }
}

final mathRepositoryProvider = Provider<MathRepository>((ref) => MathRepository(ref.watch(dioProvider)));
