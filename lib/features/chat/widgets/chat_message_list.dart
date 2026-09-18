import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../chat_controller.dart';
import '../chat_controller_legal_consent.dart';
import '../chat_controller_profiling_answer.dart';
import '../models/scheduling_messages.dart';
import '../../legal_consent/models/legal_consent_messages.dart';
import 'chat_bubble.dart';

class ChatMessageList extends StatelessWidget {
  final ChatController controller;
  final void Function(int index) onLongPress;

  const ChatMessageList({
    super.key,
    required this.controller,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.messages.isEmpty) {
          return const SizedBox.shrink();
        }
        return ListView.builder(
          controller: controller.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: controller.messages.length,
          itemBuilder: (ctx, i) {
            final msg = controller.messages[i];
            final isPlaceholder =
                !msg.isUser && msg.text.isEmpty && controller.isStreaming;
            return ChatBubble(
              message: msg,
              isStreamingPlaceholder: isPlaceholder,
              onLongPress: () => onLongPress(i),
              onSendMessage: (text) => controller.sendMessage(overrideText: text),
              // Флоу 4 (CONTRACT_flow4_scheduling_v1.md §3) — приём слота,
              // структурированный HTTP мимо streamChat()/LLM. Локализация
              // резолвится ЗДЕСЬ (у itemBuilder-контекста `ctx` есть
              // BuildContext), а не в ChatController — тот же паттерн, что
              // уже применяется для ErrorHandler.fromL10n(context.l10n) в
              // остальном приложении (см. core/api/error_handler.dart).
              onAcceptSlot: (sessionId, slotId) => controller.acceptSchedulingSlot(
                schedulingSessionId: sessionId,
                slotId: slotId,
                schedulingMessages: SchedulingMessages.fromL10n(ctx.l10n),
              ),
              // Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md
              // §4/§6) — приём medical-согласия, тот же принцип и то же
              // место резолюции локализации, что onAcceptSlot выше.
              // submitMedicalConsent — extension-метод из
              // chat_controller_legal_consent.dart (см. импорт выше),
              // не объявлен в самом ChatController — вынесен отдельно по
              // правилу "≤300-400 строк на файл" (chat_controller.dart и
              // так был на границе, 382 строки).
              onSubmitMedicalConsent: (medicalAccepted, modelTrainingAccepted) =>
                  controller.submitMedicalConsent(
                medicalDataAccepted: medicalAccepted,
                modelTrainingAccepted: modelTrainingAccepted,
                legalConsentMessages: LegalConsentMessages.fromL10n(ctx.l10n),
              ),
              // Deterministic Profiling Answer v1 (CONTRACT_deterministic_
              // profiling_answer_v1.md §2) — тот же принцип структурированного
              // HTTP мимо streamChat()/LLM, что onAcceptSlot/
              // onSubmitMedicalConsent выше. submitProfilingAnswer —
              // extension-метод из chat_controller_profiling_answer.dart
              // (см. импорт выше). ⚠ В ОТЛИЧИЕ от двух колбэков выше — этот
              // МОЖЕТ бросить исключение, здесь оно НЕ перехватывается: сам
              // ProfilingQuestionBlock ловит его и решает, что показать
              // (см. chat_bubble.dart, doc onSubmitProfilingAnswer).
              onSubmitProfilingAnswer: (slug, answerKey, value) =>
                  controller.submitProfilingAnswer(
                questionnaireSlug: slug,
                answerKey: answerKey,
                value: value,
              ),
            );
          },
        );
      },
    );
  }
}
