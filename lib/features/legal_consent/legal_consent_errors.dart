import 'package:dio/dio.dart';

/// Извлечение `blocked_reason` из тела ошибки (403 `underage`, 400
/// `consent_required` — контракт §2). Доменно-специфичная форма тела
/// ответа — не часть generic ErrorHandler (core/api/error_handler.dart).
///
/// ⚠ Живой прогон 2026-09-07 (реальное устройство, реальный backend):
/// возрастной гейт (403 underage) на практике приходил как
/// `{"detail": {"blocked_reason": "underage"}}`, а не
/// `{"blocked_reason": "underage"}` на верхнем уровне — стандартная
/// FastAPI-обёртка `HTTPException(detail=...)`. Симптом на клиенте:
/// isUnderage() возвращал false, LoginScreen проваливался в generic
/// ErrorHandler.handle() → 403 маппился на errorAuth ("Ошибка
/// авторизации. Перезапустите приложение") вместо перехода на dead-end
/// экран. Не подтверждено формально с backend-агентом, что это ЕДИНСТВЕННАЯ
/// форма ответа — проверяем ОБЕ формы defensively, ничего не теряя, если
/// контракт когда-нибудь вернётся к плоской форме.
class LegalConsentErrors {
  const LegalConsentErrors._();

  static String? extractBlockedReason(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final direct = data['blocked_reason'];
        if (direct is String) return direct;

        final detail = data['detail'];
        if (detail is Map && detail['blocked_reason'] is String) {
          return detail['blocked_reason'] as String;
        }
      }
    }
    return null;
  }

  static bool isUnderage(Object error) =>
      error is DioException &&
      error.response?.statusCode == 403 &&
      extractBlockedReason(error) == 'underage';

  static bool isConsentRequired(Object error) =>
      error is DioException &&
      error.response?.statusCode == 400 &&
      extractBlockedReason(error) == 'consent_required';
}
