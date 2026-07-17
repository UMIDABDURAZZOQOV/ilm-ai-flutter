import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';

class TelegramStatus {
  final bool linked;
  final String? reminderTime;
  final int streakDays;
  final String? lastStudyDate;

  TelegramStatus({required this.linked, this.reminderTime, required this.streakDays, this.lastStudyDate});

  factory TelegramStatus.fromJson(Map<String, dynamic> json) => TelegramStatus(
        linked: json['linked'] as bool? ?? false,
        reminderTime: json['reminder_time'] as String?,
        streakDays: json['streak_days'] as int? ?? 0,
        lastStudyDate: json['last_study_date'] as String?,
      );
}

class TelegramRepository {
  final Dio _dio;
  const TelegramRepository(this._dio);

  Future<TelegramStatus> getStatus(int userId) async {
    final res = await _dio.get('/telegram/status/$userId');
    return TelegramStatus.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> saveReminder({required int userId, required String reminderTime}) async {
    await _dio.post('/telegram/reminder', data: {'user_id': userId, 'reminder_time': reminderTime});
  }
}

final telegramRepositoryProvider = Provider<TelegramRepository>((ref) => TelegramRepository(ref.watch(dioProvider)));
