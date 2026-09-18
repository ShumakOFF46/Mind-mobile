import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';

/// Индикатор для бейджа календаря в AppBar чата: есть ли у пользователя
/// активные записи (`beauty.calendar_events`, `is_active=true`) в
/// диапазоне текущей недели (пн 00:00 — следующий пн 00:00, локальное
/// время устройства).
///
/// Бэкенд (`GET /app/calendar/events`, см. AURA_mobile.md §3.1) не
/// принимает date-range фильтр — только `category`/`active_only`,
/// поэтому фильтрация по неделе делается на клиенте по полю `start_date`
/// (snake_case, как и остальные поля `beauty.calendar_events` — см.
/// ProjectFull.md, схема `beauty.calendar_events`).
///
/// Не autoDispose: значение кэшируется на время жизни чат-экрана и
/// обновляется явно через `ref.invalidate(calendarBadgeProvider)` после
/// событий, которые могли изменить список записей.
///
/// ✅ Триггер — BRIEF_mobile_calendar_badge_invalidation_gap.md: колбэк
/// `ChatController.onCalendarChanged`, назначаемый в `chat_screen.dart`
/// (`ConsumerState`, есть `ref`) и вызываемый контроллером после
/// подтверждённого приёма слота (`acceptSchedulingSlot`) и после прихода
/// блока `calendar_event_confirmation` (cancel/reschedule) — см.
/// `chat_controller_calendar_badge.dart`. Прежний триггер
/// (`onCalendarApplied`) был удалён вместе с мёртвым passthrough-кодом
/// в BRIEF_mobile_calendar_proposal_transport_fix.md, оставляя этот gap
/// открытым до текущего брифа.
final calendarBadgeProvider = FutureProvider<bool>((ref) async {
  final List<Map<String, dynamic>> events =
      await ApiClient.getCalendarEvents(activeOnly: true);

  final now = DateTime.now();
  final weekStart = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: now.weekday - 1)); // понедельник 00:00
  final weekEnd = weekStart.add(const Duration(days: 7));

  for (final event in events) {
    final raw = event['start_date'];
    if (raw == null) continue;
    final date = DateTime.tryParse(raw.toString());
    if (date == null) continue;
    if (!date.isBefore(weekStart) && date.isBefore(weekEnd)) {
      return true;
    }
  }
  return false;
});
