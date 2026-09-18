import '../../core/api/profiling_answer_api_client.dart';
import 'chat_controller.dart';

/// Deterministic Profiling Answer v1 (CONTRACT_deterministic_profiling_
/// answer_v1.md §2) — вынесено extension'ом ИЗ chat_controller.dart по
/// тому же правилу "≤300-400 строк на файл", что уже применено к
/// ChatControllerLegalConsent (chat_controller_legal_consent.dart).
///
/// ⚠ ИНТЕГРАЦИЯ: как и submitMedicalConsent, это extension в ОТДЕЛЬНОМ
/// файле — в месте конструирования ChatBubble (chat_message_list.dart)
/// нужен доп. импорт `import 'chat_controller_profiling_answer.dart';`,
/// иначе `controller.submitProfilingAnswer(...)` не разрешится
/// компилятором.
///
/// ⚠⚠ СОЗНАТЕЛЬНОЕ РАСХОЖДЕНИЕ с ChatControllerLegalConsent.
/// submitMedicalConsent и ChatController.acceptSchedulingSlot: ОБА этих
/// метода НИКОГДА не бросают исключение наружу — сами ловят ошибку,
/// добавляют сообщение в чат, и вызывающий блок считает тап завершённым
/// в любом случае (блок скрывается/помечается отвеченным независимо от
/// исхода).
///
/// Здесь — НАОБОРОТ. Метод ниже — тонкая обёртка БЕЗ try/catch,
/// пробрасывающая DioException как есть. Это НЕ упущение, а прямое
/// требование брифа (BRIEF_mobile_deterministic_profiling_answer.md,
/// раздел "Обработка ошибки"): при ошибке ProfilingQuestionBlock должен
/// остаться в состоянии "не отвечено" — кнопки активны для повторного
/// тапа. Единственный способ добиться этого — не глотать исключение на
/// уровне контроллера, а дать виджету самому решить, что показать
/// (нейтральная ошибка + разблокированные кнопки), см.
/// profiling_question_block.dart.
///
/// По той же причине здесь НЕТ ни notifyListeners(), ни scrollToBottom():
/// сама запись ответа не меняет список сообщений чата (в отличие от
/// submitMedicalConsent/acceptSchedulingSlot, которые сразу добавляют
/// системное сообщение). Опциональное текстовое подтверждение —
/// отдельный, обычный `ChatBubble.onSendMessage` → `controller.
/// sendMessage(...)`, вызываемый виджетом ПОСЛЕ успешного return отсюда,
/// не частью этого метода.
extension ChatControllerProfilingAnswer on ChatController {
  /// `POST /api/app/profiling-answers` — структурированная запись тапа
  /// по кнопке `profiling_question`, СОЗНАТЕЛЬНО мимо streamChat()/LLM
  /// (тот же принцип, что acceptSchedulingSlot/submitMedicalConsent).
  ///
  /// Бросает [DioException] на любой не-2xx — см. класс-doc и
  /// ProfilingAnswerApiClient.
  Future<void> submitProfilingAnswer({
    required String questionnaireSlug,
    required String answerKey,
    required String value,
  }) {
    return ProfilingAnswerApiClient.submitProfilingAnswer(
      questionnaireSlug: questionnaireSlug,
      answerKey: answerKey,
      value: value,
    );
  }
}
