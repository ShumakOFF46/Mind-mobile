import 'package:dio/dio.dart';
import 'api_client.dart';

/// `POST /api/app/profiling-answers`
/// (CONTRACT_deterministic_profiling_answer_v1.md §2,
/// routers/profiling_answers.py — подтверждено чтением реального кода
/// бэкенда, не только прозой контракта).
///
/// Вынесено ИЗ api_client.dart отдельным файлом по правилу "не более
/// 300-400 строк на файл" (AGENT_RULES_mobile.md §1.1) — api_client.dart
/// уже был на границе (333 строки) до этого брифа, тот же принцип, что
/// уже применён к LegalConsentApiClient. Работает ЧЕРЕЗ публичный
/// `ApiClient.instance` (общий singleton Dio с уже настроенными token-
/// интерсепторами) — не заводит параллельный HTTP-клиент.
///
/// ⚠ В ОТЛИЧИЕ от LegalConsentApiClient/ApiClient.acceptSchedulingSlot —
/// здесь СОЗНАТЕЛЬНО НЕТ try/catch и НЕТ поглощения ошибки: любой
/// не-2xx (422 forbidden_namespace, 404 no_active_definition, 5xx, сетевая
/// ошибка) должен долететь как DioException до вызывающего кода
/// (ChatControllerProfilingAnswer.submitProfilingAnswer →
/// ProfilingQuestionBlock), потому что UX-требование брифа — оставить
/// кнопки блока активными для повторного тапа при ошибке, а не считать
/// вопрос отвеченным (см. profiling_question_block.dart, класс-doc).
class ProfilingAnswerApiClient {
  const ProfilingAnswerApiClient._();

  static Dio get _dio => ApiClient.instance;

  /// Возвращает распарсенное тело `200 OK` (`{"status": "recorded"}`).
  /// Бросает [DioException] на любой не-2xx — см. класс-doc.
  static Future<Map<String, dynamic>> submitProfilingAnswer({
    required String questionnaireSlug,
    required String answerKey,
    required String value,
  }) async {
    final response = await _dio.post('/app/profiling-answers', data: {
      'questionnaire_slug': questionnaireSlug,
      'answer_key': answerKey,
      'value': value,
    });
    return Map<String, dynamic>.from(response.data);
  }
}
