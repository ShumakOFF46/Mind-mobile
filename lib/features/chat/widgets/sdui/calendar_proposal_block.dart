import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../models/sdui/calendar_proposal_models.dart';

/// Рендер SDUI-блока `calendar_proposal` v2 (Флоу 4, негоциация слота).
/// Контракт: CONTRACT_flow4_scheduling_v1.md §1-3.
///
/// ⚠ КРИТИЧНО (см. BRIEF_mobile_flow4_scheduling_harness.md §2):
/// - Тап по кандидату слота → [onAcceptSlot] — структурированный HTTP-
///   вызов, НЕ уходит в чат как текст, НЕ идёт через streamChat()/LLM.
/// - Тап по [CalendarProposalBlockData.rejectLabel] → [onSendMessage] —
///   ОБЫЧНОЕ сообщение в чат, тот же quick-reply паттерн, что и у кнопок
///   questionnaire_prompt (label уходит как если бы пользователь напечатал
///   его сам).
///
/// `round`/`roundCap` рендерятся строго из payload через
/// `context.l10n.schedulingRoundIndicator(round, roundCap)` — контракт
/// явно запрещает хардкодить число попыток на клиенте (CONTRACT §2).
class CalendarProposalBlock extends StatefulWidget {
  final CalendarProposalBlockData data;
  final void Function(String text) onSendMessage;
  final Future<void> Function(String schedulingSessionId, String slotId)
      onAcceptSlot;

  const CalendarProposalBlock({
    super.key,
    required this.data,
    required this.onSendMessage,
    required this.onAcceptSlot,
  });

  @override
  State<CalendarProposalBlock> createState() => _CalendarProposalBlockState();
}

class _CalendarProposalBlockState extends State<CalendarProposalBlock> {
  // Блокирует повторный тап, пока не вернулся ответ на accept — сетевой
  // round-trip на структурированном пути не защищён идемпотентностью на
  // клиенте, двойной тап не должен уйти двумя параллельными POST.
  bool _isProcessing = false;

  Future<void> _handleAccept(String slotId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      await widget.onAcceptSlot(widget.data.schedulingSessionId, slotId);
    } finally {
      // ChatController сам добавляет сообщение об успехе/ошибке
      // (см. acceptSchedulingSlot()) — здесь только снимаем блокировку
      // тапа, чтобы при stale_round пользователь мог попробовать другой
      // кандидат из этого же (уже устаревшего) блока или дождаться
      // нового предложения от ассистента.
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final d = widget.data;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l.schedulingRoundIndicator(d.round, d.roundCap),
            style: TextStyle(color: c.textSub, fontSize: 12),
          ),
          const SizedBox(height: 8),
          ...d.candidates.map(
            (candidate) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed:
                    _isProcessing ? null : () => _handleAccept(candidate.slotId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.textDark,
                  side: BorderSide(color: c.accent),
                  minimumSize: const Size.fromHeight(44),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(candidate.label),
              ),
            ),
          ),
          TextButton(
            onPressed:
                _isProcessing ? null : () => widget.onSendMessage(d.rejectLabel),
            child: Text(
              d.rejectLabel,
              style: TextStyle(color: c.hint),
            ),
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 4),
            Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.accent,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Специализированное состояние calendar_proposal v2 с пустым `candidates`
/// (см. BRIEF_mobile_calendar_proposal_transport_fix.md п.2, закрытие
/// П.1-gap из REPORT_mobile_calendar_proposal_render_check.md). Раньше это
/// деградировало в generic UnknownBlock с вводящим в заблуждение текстом
/// "блок не поддерживается" — теперь понятное сообщение, что не сам блок
/// сломан, а подходящих слотов не нашлось.
///
/// ⚠ Текст — ПЛЕЙСХОЛДЕР (см. `l10n.schedulingNoSlotsFound` //
/// TODO: copy review) — финальная формулировка RU/EN требует ревью
/// копирайта, не блокирует технический фикс маршрутизации.
class CalendarProposalEmptyBlock extends StatelessWidget {
  const CalendarProposalEmptyBlock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.aiBubble,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy, size: 18, color: c.textSub),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              context.l10n.schedulingNoSlotsFound,
              style: TextStyle(fontSize: 13, color: c.textDark),
            ),
          ),
        ],
      ),
    );
  }
}
