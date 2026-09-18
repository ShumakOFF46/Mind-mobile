/// Модель блока `legal_consent_gate` (CONTRACT_legal_consent_gate_v4.md
/// §6) — ТОЛЬКО medical-гейт, контекстный.
///
/// ⚠ Контракт НЕ содержит поля `version` для этого блока (в отличие от
/// questionnaire_prompt/calendar_proposal/calendar_event_confirmation,
/// где version — обязательный дискриминатор). Диспетчер сознательно НЕ
/// делает version-гейт здесь — сверить с бэкендом, нужна ли схема
/// contracts/sdui_blocks/legal_consent_gate.schema.json с версией так
/// же, как у остальных.
class LegalConsentGateBlockData {
  final String reason; // 'declined' | 'initial'
  final List<LegalConsentGateQuestion> questions;

  const LegalConsentGateBlockData({required this.reason, required this.questions});

  factory LegalConsentGateBlockData.fromJson(Map<String, dynamic> json) {
    final reason = json['reason'];
    if (reason is! String) {
      throw const FormatException('legal_consent_gate: missing reason');
    }
    final rawQuestions = json['questions'];
    if (rawQuestions is! List || rawQuestions.isEmpty) {
      throw const FormatException('legal_consent_gate: missing questions');
    }
    return LegalConsentGateBlockData(
      reason: reason,
      questions: rawQuestions
          .map((q) => LegalConsentGateQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
          .toList(),
    );
  }
}

class LegalConsentGateQuestion {
  final String key; // 'legal:medical_data_accepted' | 'legal:model_training_accepted'
  final String label;

  const LegalConsentGateQuestion({required this.key, required this.label});

  factory LegalConsentGateQuestion.fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    if (key is! String) {
      throw const FormatException('legal_consent_gate: question without key');
    }
    // label — {"ru": "...", "en": "..."} или plain string. Если пришёл
    // объект, берём 'ru' как основной язык проекта, фолбэк на 'en'.
    final rawLabel = json['label'];
    String label;
    if (rawLabel is String) {
      label = rawLabel;
    } else if (rawLabel is Map) {
      label = rawLabel['ru']?.toString() ?? rawLabel['en']?.toString() ?? key;
    } else {
      label = key;
    }
    return LegalConsentGateQuestion(key: key, label: label);
  }
}
