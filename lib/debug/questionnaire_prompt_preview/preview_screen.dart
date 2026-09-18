import 'package:flutter/material.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/chat/models/chat_message.dart';
import 'package:vb_mobile/features/chat/widgets/chat_bubble.dart';

import 'fixtures.dart';

/// Debug-экран визуальной приёмки questionnaire_prompt (см.
/// BRIEF_mobile_questionnaire_prompt_visual_qa.md). Рендерит все 4
/// фикстуры через РЕАЛЬНЫЙ ChatBubble -> SduiBlockDispatcher, не
/// изолированный виджет — чтобы увидеть ровно то, что увидит пользователь
/// в чате.
///
/// НЕ часть прод-навигации — отдельная точка входа main_preview.dart,
/// не подключается из router.dart/основного main.dart.
class QuestionnairePromptPreviewScreen extends StatefulWidget {
  const QuestionnairePromptPreviewScreen({super.key});

  @override
  State<QuestionnairePromptPreviewScreen> createState() =>
      _QuestionnairePromptPreviewScreenState();
}

class _QuestionnairePromptPreviewScreenState
    extends State<QuestionnairePromptPreviewScreen> {
  bool _narrow = false; // false = во всю ширину устройства, true = ~360dp

  void _onSendMessage(String text) {
    // На реальном устройстве это заменяет "отправку в чат" — просто
    // показываем, что реально ушло бы на сервер, чтобы заодно проверить
    // тап по кнопкам/выбор чипов вживую, не только статичный вид.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('onSendMessage: "$text"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA: questionnaire_prompt'),
        actions: [
          IconButton(
            tooltip: _narrow ? 'Полная ширина' : 'Узкий экран (~360px)',
            icon: Icon(_narrow ? Icons.stay_primary_landscape : Icons.stay_primary_portrait),
            onPressed: () => setState(() => _narrow = !_narrow),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: previewFixtures.length,
        itemBuilder: (context, index) {
          final (title, assistantText, block) = previewFixtures[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.aura.textSub,
                      ),
                ),
                const SizedBox(height: 8),
                _NarrowConstraint(
                  narrow: _narrow,
                  child: ChatBubble(
                    message: ChatMessage(
                      text: assistantText,
                      isUser: false,
                      blocks: [block],
                    ),
                    isStreamingPlaceholder: false,
                    onLongPress: () {},
                    onSendMessage: _onSendMessage,
                    // Флоу 4 — этот QA-экран проверяет только
                    // questionnaire_prompt (см. fixtures.dart), Флоу 4
                    // блоки сюда не заведены. no-op достаточен, того же
                    // рода правка, что в questionnaire_prompt_block_test.dart
                    // (см. REPORT_mobile_flow4_scheduling_harness.md).
                    onAcceptSlot: (_, _) async {},
                    // Legal Consent Gate v4 (CONTRACT_legal_consent_
                    // gate_v4.md §6) — этот QA-экран проверяет только
                    // questionnaire_prompt, legal_consent_gate сюда не
                    // заведён. no-op достаточен, тот же принцип, что у
                    // onAcceptSlot выше.
                    onSubmitMedicalConsent: (_, _) async {},
                    // Deterministic Profiling Answer v1 — этот QA-экран
                    // проверяет только questionnaire_prompt, profiling_
                    // question сюда не заведён. no-op достаточен, тот же
                    // принцип, что у onAcceptSlot/onSubmitMedicalConsent
                    // выше.
                    onSubmitProfilingAnswer: (_, _, _) async {},
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Оборачивает контент в фиксированную ширину ~360dp (типичный узкий
/// Android-телефон), когда планшета недостаточно для проверки overflow —
/// см. п. "Дополнительно — размеры экрана" в брифе.
class _NarrowConstraint extends StatelessWidget {
  final bool narrow;
  final Widget child;

  const _NarrowConstraint({required this.narrow, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!narrow) return child;
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
        ),
        child: child,
      ),
    );
  }
}
