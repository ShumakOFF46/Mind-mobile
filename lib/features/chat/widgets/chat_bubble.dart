import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../../../core/theme.dart';
import 'sdui/sdui_block_dispatcher.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool        isStreamingPlaceholder;
  final VoidCallback onLongPress;
  final void Function(String text) onSendMessage;

  /// Флоу 4 (CONTRACT_flow4_scheduling_v1.md §3) — приём предложенного
  /// слота, структурированный HTTP мимо чата/LLM. Пробрасывается дальше
  /// в SduiBlockDispatcher/CalendarProposalBlock. ChatBubble сознательно
  /// НЕ резолвит здесь AppLocalizations сам (Interface Segregation — этот
  /// виджет не обязан знать про SchedulingMessages/l10n scheduling-строк)
  /// — коллбэк приходит уже готовым от вызывающего кода, см. п.2 отчёта:
  /// в месте конструирования ChatBubble нужно передать
  /// `(sessionId, slotId) => chatController.acceptSchedulingSlot(
  ///   schedulingSessionId: sessionId, slotId: slotId,
  ///   schedulingMessages: SchedulingMessages.fromL10n(context.l10n),
  /// )`.
  final Future<void> Function(String schedulingSessionId, String slotId)
      onAcceptSlot;

  /// Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md §4/§6) —
  /// приём medical-согласия, структурированный HTTP мимо чата/LLM,
  /// пробрасывается в SduiBlockDispatcher/LegalConsentGateBlock. Тот же
  /// принцип Interface Segregation, что уже задокументирован выше для
  /// onAcceptSlot — коллбэк приходит готовым от вызывающего кода:
  /// `(medicalAccepted, modelTrainingAccepted) => chatController
  ///   .submitMedicalConsent(
  ///     medicalDataAccepted: medicalAccepted,
  ///     modelTrainingAccepted: modelTrainingAccepted,
  ///     legalConsentMessages: LegalConsentMessages.fromL10n(context.l10n),
  ///   )`.
  /// ⚠ `submitMedicalConsent` — extension-метод из
  /// `chat_controller_legal_consent.dart` (НЕ объявлен в самом
  /// ChatController — вынесен отдельно по правилу "≤300-400 строк на
  /// файл", chat_controller.dart и так был на границе). В месте
  /// конструирования ChatBubble нужен доп. импорт этого extension-файла.
  final Future<void> Function(
    bool medicalDataAccepted,
    bool modelTrainingAccepted,
  ) onSubmitMedicalConsent;

  /// Deterministic Profiling Answer v1 (CONTRACT_deterministic_profiling_
  /// answer_v1.md §2) — приём тапа по кнопке `profiling_question`,
  /// структурированный HTTP мимо чата/LLM, пробрасывается в
  /// SduiBlockDispatcher/ProfilingQuestionBlock. Тот же принцип Interface
  /// Segregation, что и остальные структурированные колбэки выше — коллбэк
  /// приходит готовым от вызывающего кода:
  /// `(slug, answerKey, value) => chatController.submitProfilingAnswer(
  ///   questionnaireSlug: slug, answerKey: answerKey, value: value,
  /// )`.
  /// ⚠ `submitProfilingAnswer` — extension-метод из
  /// `chat_controller_profiling_answer.dart` (не объявлен в самом
  /// ChatController, тот же принцип "≤300-400 строк на файл", что и
  /// submitMedicalConsent). В месте конструирования ChatBubble нужен доп.
  /// импорт этого extension-файла.
  /// ⚠⚠ В ОТЛИЧИЕ от onAcceptSlot/onSubmitMedicalConsent — этот коллбэк
  /// МОЖЕТ бросить исключение (см. profiling_question_block.dart,
  /// класс-doc, и sdui_block_dispatcher.dart).
  final Future<void> Function(
    String questionnaireSlug,
    String answerKey,
    String value,
  ) onSubmitProfilingAnswer;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isStreamingPlaceholder,
    required this.onLongPress,
    required this.onSendMessage,
    required this.onAcceptSlot,
    required this.onSubmitMedicalConsent,
    required this.onSubmitProfilingAnswer,
  });

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return message.isUser ? _UserBubble(this) : _AiBubble(this);
  }
}

class _UserBubble extends StatelessWidget {
  final ChatBubble w;
  const _UserBubble(this.w);

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return GestureDetector(
      onLongPress: w.onLongPress,
      child: Align(
        alignment: Alignment.centerRight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Картинка над текстом если есть
            if (w.message.imageUrl != null)
              Container(
                margin: const EdgeInsets.only(bottom: 4, left: 60),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    w.message.imageUrl!,
                    width:     200,
                    height:    200,
                    fit:       BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 200, height: 200,
                      color: c.aiBubble,
                      child: Icon(Icons.broken_image_outlined,
                          color: c.textSub),
                    ),
                  ),
                ),
              ),
            Container(
              margin:  const EdgeInsets.only(bottom: 2, left: 60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        c.userBubble,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(
                w.message.text,
                style: TextStyle(
                  color:      c.textDark,
                  fontSize:   15,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w400,
                  height:     1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (w.message.liked)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.favorite, color: c.accent, size: 11),
                    ),
                  Text(
                    w._formatTime(w.message.timestamp),
                    style: TextStyle(
                      color:      c.textSub,
                      fontSize:   10,
                      fontFamily: 'Roboto',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiBubble extends StatelessWidget {
  final ChatBubble w;
  const _AiBubble(this.w);

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final blocks = w.message.blocks;
    return GestureDetector(
      onLongPress: w.onLongPress,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin:  const EdgeInsets.only(bottom: 2, right: 60),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color:        c.aiBubble,
                borderRadius: BorderRadius.circular(18),
              ),
              child: w.isStreamingPlaceholder
                  ? _TypingIndicator(color: c.textSub)
                  : Text(
                      w.message.text,
                      style: TextStyle(
                        color:      c.textDark,
                        fontSize:   15,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        height:     1.4,
                      ),
                    ),
            ),
            // ── SDUI-блоки сообщения (generic blocks, см. ChatMessage.blocks) ──
            if (!w.isStreamingPlaceholder && blocks != null && blocks.isNotEmpty)
              ...blocks.map(
                (block) => SduiBlockDispatcher.build(
                  block,
                  onSendMessage: w.onSendMessage,
                  onAcceptSlot: w.onAcceptSlot,
                  onSubmitMedicalConsent: w.onSubmitMedicalConsent,
                  onSubmitProfilingAnswer: w.onSubmitProfilingAnswer,
                ),
              ),
            // ─────────────────────────────────────────────────────────────────
            if (!w.isStreamingPlaceholder)
              Padding(
                padding: const EdgeInsets.only(bottom: 8, left: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w._formatTime(w.message.timestamp),
                      style: TextStyle(
                        color:      c.textSub,
                        fontSize:   10,
                        fontFamily: 'Roboto',
                      ),
                    ),
                    if (w.message.liked) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.favorite, color: c.accent, size: 11),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Typing indicator ─────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  final Color color;
  const _TypingIndicator({required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _Dot(delay: i * 200, color: color)),
    );
  }
}

class _Dot extends StatefulWidget {
  final int   delay;
  final Color color;
  const _Dot({required this.delay, required this.color});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(
        Duration(milliseconds: widget.delay),
        () { if (mounted) _ctrl.repeat(reverse: true); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _anim,
    child: Container(
      width: 7, height: 7,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
    ),
  );
}
