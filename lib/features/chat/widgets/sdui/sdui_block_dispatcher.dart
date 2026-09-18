import 'package:flutter/material.dart';
import '../../models/sdui/questionnaire_prompt_models.dart';
import '../../models/sdui/calendar_proposal_models.dart';
import '../../models/sdui/calendar_event_confirmation_models.dart';
import '../../models/sdui/legal_consent_gate_models.dart';
import '../../models/sdui/profiling_question_models.dart';
import 'questionnaire_prompt_block.dart';
import 'calendar_proposal_block.dart';
import 'calendar_event_confirmation_block.dart';
import 'legal_consent_gate_block.dart';
import 'profiling_question_block.dart';
import 'unknown_block.dart';

/// Точка входа рендера generic SDUI-блоков сообщения чата.
///
/// Зарегистрированы `questionnaire_prompt`, `calendar_proposal` (Флоу 4,
/// v2), `calendar_event_confirmation` (Флоу 4, v1) и `legal_consent_gate`
/// (Legal Consent Gate v4, CONTRACT_legal_consent_gate_v4.md §6,
/// medical-гейт). buttons/media/link/gif здесь по-прежнему сознательно
/// НЕ диспетчеризуются — вне объёма.
///
/// `calendar_proposal` требует ДВА разных канала отправки данных обратно
/// (CONTRACT_flow4_scheduling_v1.md §1, §3):
/// - [onSendMessage] — обычное текстовое сообщение в чат (reject_label,
///   как и кнопки questionnaire_prompt);
/// - [onAcceptSlot] — структурированный HTTP-вызов МИМО чата/LLM (приём
///   слота уже структурирован тапом, экстракция текста не нужна).
///
/// `calendar_event_confirmation` — НЕинтерактивный блок (CONTRACT §4a),
/// ни одного из этих двух колбэков не использует.
///
/// `legal_consent_gate` — третий структурированный канал:
/// - [onSubmitMedicalConsent] — POST /app/legal-consent/medical мимо
///   чата/LLM (тот же принцип, что onAcceptSlot). НИКОГДА не бросает
///   исключение — реализация (ChatController.submitMedicalConsent) сама
///   ловит ошибки и добавляет сообщение в чат.
///
/// `profiling_question` (CONTRACT_deterministic_profiling_answer_v1.md
/// §1-2) — четвёртый структурированный канал, но с ОБРАТНЫМ контрактом
/// ошибки относительно трёх предыдущих:
/// - [onSubmitProfilingAnswer] — POST /app/profiling-answers мимо
///   чата/LLM. В ОТЛИЧИЕ от onAcceptSlot/onSubmitMedicalConsent — МОЖЕТ
///   и ДОЛЖЕН бросать исключение наружу (реализация:
///   ChatControllerProfilingAnswer.submitProfilingAnswer, БЕЗ try/catch).
///   Причина — UX-требование брифа: при ошибке кнопки блока должны
///   остаться активными для повторного тапа, что возможно только если
///   ProfilingQuestionBlock сам ловит ошибку, а не контроллер (см.
///   profiling_question_block.dart, класс-doc).
class SduiBlockDispatcher {
  const SduiBlockDispatcher._();

  static Widget build(
    Map<String, dynamic> block, {
    required void Function(String text) onSendMessage,
    required Future<void> Function(String schedulingSessionId, String slotId)
        onAcceptSlot,
    required Future<void> Function(
      bool medicalDataAccepted,
      bool modelTrainingAccepted,
    ) onSubmitMedicalConsent,
    required Future<void> Function(
      String questionnaireSlug,
      String answerKey,
      String value,
    ) onSubmitProfilingAnswer,
  }) {
    final type = block['type'];
    switch (type) {
      case 'questionnaire_prompt':
        return _buildQuestionnairePrompt(block, onSendMessage);
      case 'calendar_proposal':
        return _buildCalendarProposal(block, onSendMessage, onAcceptSlot);
      case 'calendar_event_confirmation':
        return _buildCalendarEventConfirmation(block);
      case 'legal_consent_gate':
        return _buildLegalConsentGate(block, onSubmitMedicalConsent);
      case 'profiling_question':
        return _buildProfilingQuestion(
            block, onSendMessage, onSubmitProfilingAnswer);
      default:
        return UnknownBlock(blockType: type?.toString());
    }
  }

  static Widget _buildQuestionnairePrompt(
    Map<String, dynamic> block,
    void Function(String text) onSendMessage,
  ) {
    // ⚠ Контрактный ключ — `version` (см. contracts/sdui_blocks/
    // questionnaire_prompt.schema.json). `block_version` — не существует
    // ни в схеме, ни в реальном ответе бэкенда (см.
    // REPORT_mobile_verify_questionnaire_prompt_field_names.md, 2026-08-16).
    final blockVersion = block['version'];
    if (blockVersion != 1) {
      return UnknownBlock(blockType: 'questionnaire_prompt@$blockVersion');
    }

    try {
      final data = QuestionnairePromptBlockData.fromJson(block);
      if (data.questions.isEmpty) {
        return const UnknownBlock(
            blockType: 'questionnaire_prompt (empty questions)');
      }
      return QuestionnairePromptBlock(data: data, onSendMessage: onSendMessage);
    } on FormatException catch (e) {
      debugPrint('SDUI: malformed questionnaire_prompt block: $e');
      return const UnknownBlock(blockType: 'questionnaire_prompt (malformed)');
    }
  }

  static Widget _buildCalendarProposal(
    Map<String, dynamic> block,
    void Function(String text) onSendMessage,
    Future<void> Function(String schedulingSessionId, String slotId)
        onAcceptSlot,
  ) {
    // ⚠ Контрактный ключ — `version` (CONTRACT_flow4_scheduling_v1.md §2).
    // Ровно тот класс проверки, что уже был исправлен для
    // questionnaire_prompt (клиент раньше резолвил по несуществующему
    // `block_version`) — не повторять тот же класс ошибки на новом блоке.
    final blockVersion = block['version'];
    if (blockVersion != 2) {
      return UnknownBlock(blockType: 'calendar_proposal@$blockVersion');
    }

    try {
      final data = CalendarProposalBlockData.fromJson(block);
      if (data.candidates.isEmpty) {
        // По контракту backend в норме не присылает пустой candidates
        // как блок вообще (CONTRACT §2), но после фикса маршрутизации
        // (BRIEF_mobile_calendar_proposal_transport_fix.md п.1) этот путь
        // стал реально достижимым для реального трафика — специализированное
        // состояние вместо generic UnknownBlock (см. п.2 того же брифа).
        return const CalendarProposalEmptyBlock();
      }
      return CalendarProposalBlock(
        data: data,
        onSendMessage: onSendMessage,
        onAcceptSlot: onAcceptSlot,
      );
    } on FormatException catch (e) {
      debugPrint('SDUI: malformed calendar_proposal block: $e');
      return const UnknownBlock(blockType: 'calendar_proposal (malformed)');
    }
  }

  static Widget _buildCalendarEventConfirmation(Map<String, dynamic> block) {
    // ⚠ Контрактный ключ — `version` (CONTRACT_flow4_scheduling_v1.md
    // §4a). Тот же принцип резолюции, что и для questionnaire_prompt/
    // calendar_proposal — по полю `version`, не по альтернативному имени.
    final blockVersion = block['version'];
    if (blockVersion != 1) {
      return UnknownBlock(
          blockType: 'calendar_event_confirmation@$blockVersion');
    }

    try {
      final data = CalendarEventConfirmationBlockData.fromJson(block);
      return CalendarEventConfirmationBlock(data: data);
    } on FormatException catch (e) {
      debugPrint('SDUI: malformed calendar_event_confirmation block: $e');
      return const UnknownBlock(
          blockType: 'calendar_event_confirmation (malformed)');
    }
  }

  static Widget _buildLegalConsentGate(
    Map<String, dynamic> block,
    Future<void> Function(bool, bool) onSubmitMedicalConsent,
  ) {
    // ⚠ CONTRACT_legal_consent_gate_v4.md §6 НЕ содержит поля `version`
    // для этого блока (в отличие от case'ов выше) — см.
    // legal_consent_gate_models.dart. Version-гейт здесь сознательно
    // отсутствует, сверить с бэкендом при появлении .schema.json.
    try {
      final data = LegalConsentGateBlockData.fromJson(block);
      return LegalConsentGateBlock(data: data, onSubmit: onSubmitMedicalConsent);
    } on FormatException catch (e) {
      debugPrint('SDUI: malformed legal_consent_gate block: $e');
      return const UnknownBlock(blockType: 'legal_consent_gate (malformed)');
    }
  }

  static Widget _buildProfilingQuestion(
    Map<String, dynamic> block,
    void Function(String text) onSendMessage,
    Future<void> Function(String, String, String) onSubmitProfilingAnswer,
  ) {
    // ⚠ profiling_question.schema.json НЕ содержит поля `version` (как и
    // legal_consent_gate) — версионирование блока контрактом не заложено
    // в v1, гейта по номеру версии здесь сознательно нет, тот же принцип,
    // что у _buildLegalConsentGate.
    try {
      final data = ProfilingQuestionBlockData.fromJson(block);
      return ProfilingQuestionBlock(
        data: data,
        onSendMessage: onSendMessage,
        onSubmitAnswer: onSubmitProfilingAnswer,
      );
    } on FormatException catch (e) {
      debugPrint('SDUI: malformed profiling_question block: $e');
      return const UnknownBlock(blockType: 'profiling_question (malformed)');
    }
  }
}
