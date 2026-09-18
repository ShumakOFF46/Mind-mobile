import 'package:flutter/foundation.dart';
import '../../core/api/legal_consent_api_client.dart';
import '../../core/api/error_handler.dart';
import 'chat_controller.dart';
import 'models/chat_message.dart';
import '../legal_consent/models/legal_consent_messages.dart';

/// Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md §4/§6) —
/// вынесены extension'ом ИЗ chat_controller.dart, чтобы не раздувать файл
/// сверх правила "не более 300-400 строк" (chat_controller.dart и так был
/// на границе — 382 строки до этого брифа, поэтому сам файл здесь НЕ
/// тронут вообще). Extension использует публичные члены ChatController
/// (messages/scrollToBottom()) напрямую и `notifyChatListeners()` для
/// уведомления слушателей — НЕ `notifyListeners()` напрямую, он
/// `@protected` внутри `ChangeNotifier` и недоступен extension'у из
/// другого файла (найдено `flutter analyze`, 2026-09-06:
/// invalid_use_of_protected_member/invalid_use_of_visible_for_testing_
/// member). Тот же принцип структурированного HTTP мимо LLM, что уже
/// применён к acceptSchedulingSlot() в самом chat_controller.dart
/// (метод оставлен на месте, вне скоупа этого брифа — не задублирован
/// здесь).
///
/// ⚠ ВАЖНО ДЛЯ ИНТЕГРАЦИИ: поскольку это extension в ОТДЕЛЬНОМ файле, в
/// месте конструирования ChatBubble (там, где сейчас вызывается
/// `controller.acceptSchedulingSlot(...)` — предположительно
/// chat_message_list.dart, файл не был предоставлен) нужно ДОПОЛНИТЕЛЬНО
/// добавить:
/// `import 'chat_controller_legal_consent.dart';`
/// иначе `controller.submitMedicalConsent(...)` не разрешится компилятором.
extension ChatControllerLegalConsent on ChatController {
  /// Приём согласия на medical-данные/обучение моделей — вызывается из
  /// LegalConsentGateBlock (через SduiBlockDispatcher → ChatBubble →
  /// сюда), НЕ из sendMessage() — структурированный HTTP-вызов,
  /// СОЗНАТЕЛЬНО мимо streamChat()/LLM. Тот же принцип, что уже применён
  /// к acceptSchedulingSlot(): тап уже структурирован (чекбоксы), событие
  /// уже произошло на структурированном пути, ассистент не формулирует
  /// этот ответ сам.
  ///
  /// [legalConsentMessages] — резолвится вызывающим кодом через
  /// `LegalConsentMessages.fromL10n(context.l10n)`, тот же паттерн, что
  /// SchedulingMessages у acceptSchedulingSlot().
  ///
  /// НИКОГДА не бросает исключение наружу (как и acceptSchedulingSlot) —
  /// LegalConsentGateBlock полагается на это, чтобы всегда скрывать себя
  /// после одного `await`, независимо от исхода; исход сообщается через
  /// добавленное сюда сообщение в чате.
  Future<void> submitMedicalConsent({
    required bool medicalDataAccepted,
    required bool modelTrainingAccepted,
    required LegalConsentMessages legalConsentMessages,
  }) async {
    try {
      final result = await LegalConsentApiClient.submitMedicalConsent(
        medicalDataAccepted: medicalDataAccepted,
        modelTrainingAccepted: modelTrainingAccepted,
      );
      messages.add(ChatMessage(
        text: result.passed
            ? legalConsentMessages.accepted
            : legalConsentMessages.declined,
        isUser: false,
      ));
    } catch (e) {
      debugPrint('submitMedicalConsent error: $e');
      final appError = ErrorHandler.handle(e, ErrorHandler.defaultMessages);
      messages.add(ChatMessage(text: appError.message, isUser: false));
    } finally {
      notifyChatListeners();
      scrollToBottom();
    }
  }
}
