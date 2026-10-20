import 'package:dio/dio.dart';

/// Ported from ilm-ai-mobile's utils/errorMessage.ts -- always returns a
/// human-readable string, never a raw exception object.
String extractError(Object err, {String language = 'en'}) {
  String text(String uz, String ru, String en) => language == 'uz' ? uz : language == 'ru' ? ru : en;
  if (err is DioException) {
    if (err.type == DioExceptionType.connectionError || err.type == DioExceptionType.connectionTimeout) {
      return text('Internetga ulanib bo‘lmadi. Ulanishni tekshiring.', 'Нет подключения к интернету. Проверьте соединение.', 'No internet connection');
    }
    if (err.type == DioExceptionType.receiveTimeout || err.type == DioExceptionType.sendTimeout) {
      return text('So‘rov vaqti tugadi. Qayta urinib ko‘ring.', 'Время ожидания истекло. Повторите попытку.', 'Request timed out. Please try again.');
    }
    final status = err.response?.statusCode;
    if (status != null && status >= 500) {
      return text('Serverda xatolik. Birozdan so‘ng qayta urining.', 'Ошибка сервера. Повторите попытку позже.', 'Server error ($status). Please try again in a moment.');
    }
    if (status == 401) return text('Sessiya tugadi. Qayta kiring.', 'Сеанс истёк. Войдите снова.', 'Your session expired. Please sign in again.');
    if (status == 403) return text('Bu amal hozir mavjud emas. Oldingi bosqichlarni tekshiring.', 'Действие пока недоступно. Проверьте предыдущие этапы.', 'This action is unavailable. Check the preceding steps.');
    if (status == 409) return text('Urinishni tekshiring yoki qayta oching. Saqlangan natija yo‘qolmaydi.', 'Проверьте или откройте попытку заново. Сохранённый результат останется.', 'Check or reopen this attempt. Saved results are preserved.');
    if (status == 422 || status == 400) return text('Ma’lumotlarni tekshirib, qayta urining.', 'Проверьте данные и повторите попытку.', 'Check the entered details and try again.');
  }
  return text('Amal bajarilmadi. Qayta urinib ko‘ring.', 'Не удалось выполнить действие. Повторите попытку.', 'Request failed. Please try again.');
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
