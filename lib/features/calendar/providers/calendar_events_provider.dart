import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../models/procedure_event.dart';

/// Реальные данные календаря — GET /app/calendar/events (Step 0 fix,
/// BRIEF_mobile_flow4_scheduling_harness.md, п.0). Заменяет
/// mockAugust2026Procedures() в calendar_screen.dart.
///
/// `autoDispose` ОСОЗНАННО, по прямой аналогии с уже существующим
/// `calendarDisplayedMonthProvider`: `CalendarScreen` — отдельный
/// `go_router`-route, полностью размонтируется при `pop()`. При повторном
/// открытии виджет пересоздаётся, `autoDispose`-провайдер стартует
/// заново — это и есть «рефетч на каждый фокус»
/// (CONTRACT_flow4_scheduling_v1.md §5 / BRIEF п.3), БЕЗ RouteObserver.
///
/// Мэппинг JSON→ProcedureEvent сверен построчно с `routers/app_calendar.py`
/// (`GET /events`, см. цитаты ниже) — это уже НЕ гипотеза, как в
/// предыдущей версии файла.
final calendarEventsProvider =
    FutureProvider.autoDispose<List<ProcedureEvent>>((ref) async {
  final raw = await ApiClient.getCalendarEvents();
  return raw.map(_mapEventJson).toList();
});

ProcedureEvent _mapEventJson(Map<String, dynamic> json) {
  final recurrence = _asRecurrenceMap(json['recurrence']);
  return ProcedureEvent(
    id: json['id'] as String,
    title: json['title'] as String,
    dateTime: _resolveDateTime(json['start_date'] as String?, recurrence),
    category: _resolveCategory(json['category'] as String?),
    notes: json['notes'] as String?,
    durationMinutes: json['duration_minutes'] as int?,
  );
}

/// `start_date` — ФАКТ из app_calendar.py: `row["start_date"].isoformat()`
/// на Python `date` (не `datetime`!) → строка вида "YYYY-MM-DD", БЕЗ
/// времени суток. Реальное время процедуры лежит в
/// `recurrence.time` ("HH:MM", см. `CalendarEvent.recurrence`
/// докстринг-комментарий в app_calendar.py: `{"type": ..., "days": [...],
/// "time": "HH:MM"}`). Наивный `DateTime.parse(start_date)` без этой
/// поправки давал бы полночь для КАЖДОЙ процедуры — было бы тихой
/// ошибкой, не крашем.
DateTime _resolveDateTime(String? startDateStr, Map<String, dynamic>? recurrence) {
  if (startDateStr == null) return DateTime.now();
  DateTime datePart;
  try {
    datePart = DateTime.parse(startDateStr);
  } catch (_) {
    return DateTime.now();
  }
  final timeStr = recurrence?['time'];
  if (timeStr is! String) return datePart;
  final segments = timeStr.split(':');
  final hour   = segments.isNotEmpty ? int.tryParse(segments[0]) ?? 0 : 0;
  final minute = segments.length > 1 ? int.tryParse(segments[1]) ?? 0 : 0;
  return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
}

/// ✅ ПОДТВЕРЖДЕНО (db/database.py): `postgresql+asyncpg://` через
/// `create_async_engine()` — SQLAlchemy-диалект `asyncpg` регистрирует
/// `type_codec` для `json`/`jsonb` НА УРОВНЕ СОЕДИНЕНИЯ (не колонки), это
/// применяется и к raw `text()`-запросам без явного SQLAlchemy JSON-типа
/// — `recurrence` приходит уже как Python `dict`, не строка. Ветка на
/// `String` ниже оставлена как safety-net (например, на случай смены
/// диалекта/драйвера в будущем), а не потому что это ожидаемый случай.
Map<String, dynamic>? _asRecurrenceMap(dynamic raw) {
  if (raw is Map) return Map<String, dynamic>.from(raw);
  if (raw is String) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // не валидный JSON — трактуем как отсутствие recurrence
    }
  }
  return null;
}

/// ✅ ЗАКРЫТО (было gap, теперь явный бакет): `CalendarEvent.category` на
/// бэкенде — свободная строка со значением по умолчанию `"skincare"`
/// (app_calendar.py, строка 18), которого среди исходных 4 членов
/// ProcedureCategory не было. Добавлен `ProcedureCategory.other`
/// (procedure_event.dart) + case в category_label.dart — любая
/// несовпадающая по имени категория теперь попадает в явный,
/// нейтрально оформленный "Other"/"Другое" бакет, а не молча
/// маскируется под "Serum" (что и было исходным риском). debugPrint
/// остаётся — не для сигнала о недостающем коде, а чтобы в логах было
/// видно РЕАЛЬНОЕ распределение backend-категорий (полезно при решении,
/// стоит ли когда-нибудь заводить `skincare` отдельным членом).
ProcedureCategory _resolveCategory(String? raw) {
  for (final c in ProcedureCategory.values) {
    if (c.name == raw) return c;
  }
  debugPrint(
    'calendarEventsProvider: категория "$raw" не входит в ProcedureCategory '
    'по имени — отображается как ${ProcedureCategory.other.name}',
  );
  return ProcedureCategory.other;
}
