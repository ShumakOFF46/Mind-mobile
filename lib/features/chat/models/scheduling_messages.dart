import '../../../core/l10n/app_localizations.dart';

/// Локализованные строки для клиентских (не-LLM) сообщений Флоу 4 —
/// подтверждение/ошибка приёма слота (CONTRACT_flow4_scheduling_v1.md §3).
///
/// Паттерн — прямая калька с `ErrorMessages`/`ErrorHandler.fromL10n()`
/// (core/api/error_handler.dart): строки резолвятся ОДИН РАЗ в виджете,
/// у которого есть `BuildContext` (там, где создаётся коллбэк
/// `onAcceptSlot`, передаваемый в `SduiBlockDispatcher`/`ChatBubble`), и
/// передаются в `ChatController.acceptSchedulingSlot()` готовым объектом —
/// контроллер сам `BuildContext` не имеет и иметь не должен.
class SchedulingMessages {
  final String confirmed;
  final String staleRound;
  final String notFound;
  final String notOwner;
  final String genericError;

  const SchedulingMessages({
    required this.confirmed,
    required this.staleRound,
    required this.notFound,
    required this.notOwner,
    required this.genericError,
  });

  factory SchedulingMessages.fromL10n(AppLocalizations l) => SchedulingMessages(
    confirmed:    l.schedulingSlotConfirmed,
    staleRound:   l.schedulingSlotStaleRound,
    notFound:     l.schedulingSlotNotFound,
    notOwner:     l.schedulingSlotNotOwner,
    genericError: l.schedulingSlotGenericError,
  );

  /// Мапинг `reason` из ответа `/accept` (CONTRACT §3) на локализованную
  /// строку. Неизвестный/отсутствующий reason → generic (fail-safe, не
  /// падаем и не показываем null).
  ///
  /// ⚠ ПОДТВЕРЖДЕНО backend'ом (REPORT_backend_flow4_mobile_verification_
  /// response.md, 2026-09-03): ветка "сессия уже resolved (confirmed/
  /// abandoned)" возвращает тот же `reason: "not_found"`, что и "сессии
  /// вообще нет" — backend НЕ различает эти два случая на уровне reason.
  /// Осознанно НЕ развожу их на клиенте отдельным UI-сообщением (не
  /// implicit-упущение) — если понадобится точнее объяснить пользователю
  /// "запись уже подтверждена" отдельно от "не нашли сессию", это
  /// маленький backend-фикс (новый reason, например "already_resolved"),
  /// backend сам предложил это в своём отчёте, не мой самостоятельный
  /// выбор архитектуры.
  String forReason(String? reason) {
    switch (reason) {
      case 'stale_round': return staleRound;
      case 'not_found':   return notFound;
      case 'not_owner':   return notOwner;
      default:            return genericError;
    }
  }
}
