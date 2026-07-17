import 'package:dio/dio.dart';

/// Ported from ilm-ai-mobile's utils/errorMessage.ts -- always returns a
/// human-readable string, never a raw exception object.
String extractError(Object err) {
  if (err is DioException) {
    final data = err.response?.data;
    if (data is Map) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List) {
        return detail.map((d) => d is Map && d['msg'] != null ? d['msg'].toString() : d.toString()).join(', ');
      }
      if (detail is Map && detail['message'] != null) return detail['message'].toString();
      final message = data['message'];
      if (message is String) return message;
    }
    if (err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout) {
      return 'No internet connection';
    }
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return 'Server error ($statusCode). Please try again in a moment.';
    }
    if (err.type == DioExceptionType.receiveTimeout || err.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }
    return 'Request failed. Please try again.';
  }
  if (err is Exception) {
    final s = err.toString();
    return s.startsWith('Exception: ') ? s.substring(11) : s;
  }
  return 'An unexpected error occurred. Please try again.';
}

/// Login fails with a structured 403 { code: "email_not_verified", email }
/// when an account hasn't confirmed its verification code yet.
String? getUnverifiedEmail(Object err) {
  if (err is DioException && err.response?.statusCode == 403) {
    final detail = err.response?.data is Map ? (err.response!.data as Map)['detail'] : null;
    if (detail is Map && detail['code'] == 'email_not_verified') {
      return detail['email'] as String?;
    }
  }
  return null;
}
