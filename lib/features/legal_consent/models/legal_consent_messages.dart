import '../../../core/l10n/app_localizations.dart';

/// Локализованные строки для подтверждения medical-гейта прямо в чате
/// (CONTRACT_legal_consent_gate_v4.md §4/§6). Резолвятся ВЫЗЫВАЮЩИМ
/// КОДОМ, у которого есть BuildContext (место конструирования ChatBubble)
/// — ChatController сам l10n не резолвит. Тот же паттерн, что уже
/// применён к SchedulingMessages.fromL10n() для Флоу 4
/// (chat_controller.dart::acceptSchedulingSlot()) — не новый прецедент.
class LegalConsentMessages {
  final String accepted;
  final String declined;

  const LegalConsentMessages({
    required this.accepted,
    required this.declined,
  });

  factory LegalConsentMessages.fromL10n(AppLocalizations l) =>
      LegalConsentMessages(
        accepted: l.legalMedicalConsentAcceptedMessage,
        declined: l.legalMedicalConsentDeclinedMessage,
      );
}
