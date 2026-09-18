import 'package:flutter/material.dart';
import '../../../../core/theme.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../models/sdui/calendar_event_confirmation_models.dart';

/// Рендер SDUI-блока `calendar_event_confirmation` v1 (Флоу 4).
/// Контракт: CONTRACT_flow4_scheduling_v1.md §4a.
///
/// НЕинтерактивная информационная карточка — сознательно БЕЗ
/// onSendMessage/onAcceptSlot и БЕЗ единого тапабельного элемента
/// (GestureDetector/InkWell/*Button) в дереве. Блок приходит только по
/// факту уже свершившегося действия — backend гарантирует это ДО отправки
/// блока (BRIEF §1: "приходит ... ТОЛЬКО при реальной успешной записи в
/// БД"), клиенту нечего подтверждать повторно и нечего отклонять.
class CalendarEventConfirmationBlock extends StatelessWidget {
  final CalendarEventConfirmationBlockData data;

  const CalendarEventConfirmationBlock({super.key, required this.data});

  /// Формат "12 Сен · 18:00" — та же конвенция (день + короткий месяц +
  /// время через TimeOfDay.format), что уже используется в
  /// procedure_detail_sheet.dart для отображения даты/времени процедуры.
  ///
  /// ⚠ Явный `.toLocal()`: контракт передаёт ISO8601 со смещением
  /// ("+03:00"), в отличие от мок-данных остального календарного UI (без
  /// tz, прецедента на этот случай в существующем коде не было). Без
  /// этого `TimeOfDay.format()` показал бы время в UTC, не локальное.
  String _formatInstant(BuildContext context, String iso) {
    final l = context.l10n;
    DateTime dt;
    try {
      dt = DateTime.parse(iso).toLocal();
    } catch (_) {
      return iso; // не распарсилось — показываем как есть, не падаем
    }
    final day = dt.day;
    final monthAbbr = l.monthShortLabels[dt.month - 1];
    final time = TimeOfDay.fromDateTime(dt).format(context);
    return '$day $monthAbbr · $time';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final isRescheduled = data.action == 'rescheduled' && data.previous != null;
    final isCancelled = data.action == 'cancelled';

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
          Row(
            children: [
              Icon(
                isRescheduled ? Icons.update_rounded : Icons.event_busy_rounded,
                size: 16,
                color: c.textSub,
              ),
              const SizedBox(width: 6),
              Text(
                isRescheduled
                    ? l.calendarConfirmationRescheduledLabel
                    : l.calendarConfirmationCancelledLabel,
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.event.title,
            style: TextStyle(
              color: c.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          if (isRescheduled) ...[
            Row(
              children: [
                Text(
                  '${l.calendarConfirmationWasLabel}: ',
                  style: TextStyle(color: c.textSub, fontSize: 13),
                ),
                Text(
                  _formatInstant(context, data.previous!.start),
                  style: TextStyle(
                    color: c.textSub,
                    fontSize: 13,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '${l.calendarConfirmationNowLabel}: ',
                  style: TextStyle(
                    color: c.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatInstant(context, data.event.start),
                  style: TextStyle(
                    color: c.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else
            Text(
              _formatInstant(context, data.event.start),
              style: TextStyle(
                color: c.textSub,
                fontSize: 13,
                // Зачёркивание — только для достоверно 'cancelled'.
                // Неизвестный action (isKnownAction == false) рендерится
                // нейтрально, без зачёркивания — не домысливаем визуал
                // для значения, которого не знаем.
                decoration: isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
        ],
      ),
    );
  }
}
