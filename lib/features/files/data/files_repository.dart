import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import 'files_models.dart';

class FilesRepository {
  final Dio _dio;
  const FilesRepository(this._dio);

  Future<List<FileItem>> list(int userId) async {
    final res = await _dio.get('/files/list', queryParameters: {'user_id': userId});
    final data = res.data as Map<String, dynamic>;
    return (data['files'] as List? ?? []).map((e) => FileItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Multipart upload from raw bytes -- unlike ilm-ai-mobile's web-vs-native
  /// FormData branching, Dio's MultipartFile.fromBytes works uniformly
  /// across platforms since file_picker's picked-file bytes are already
  /// in-memory.
  Future<void> upload({required int userId, required String topic, required String filename, required List<int> bytes}) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    await _dio.post('/files/upload', queryParameters: {'user_id': userId, 'topic': topic}, data: formData);
  }

  Future<void> uploadText({required int userId, required String filename, required String text, required String topic}) async {
    await _dio.post('/files/upload-text', data: {'user_id': userId, 'filename': filename, 'text': text, 'topic': topic});
  }

  Future<void> delete({required int userId, required String filename}) async {
    await _dio.delete('/files/delete', queryParameters: {'user_id': userId, 'filename': filename});
  }

  Future<void> updateTopic({required int userId, required String filename, required String newTopic}) async {
    await _dio.patch('/files/update-topic', data: {'user_id': userId, 'filename': filename, 'topic': newTopic});
  }
}

final filesRepositoryProvider = Provider<FilesRepository>((ref) => FilesRepository(ref.watch(dioProvider)));
