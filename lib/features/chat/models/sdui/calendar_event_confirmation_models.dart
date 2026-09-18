/// Модели данных SDUI-блока `calendar_event_confirmation` v1 (Флоу 4).
/// Контракт: CONTRACT_flow4_scheduling_v1.md §4a.
///
/// ✅ Форма подтверждена ЖИВЫМ PAYLOAD (MOBILE_HANDOFF_calendar_event_
/// confirmation_dumps.md, 2026-09-XX) — два реальных дампа через полный
/// agentic loop (`POST /api/chat`, реальный LLM tool-call), не через
/// прямой вызов backend-функций. ⚠ Формального
/// `contracts/sdui_blocks/calendar_event_confirmation.schema.json` на
/// сервере backend всё ещё физически НЕТ (только `calendar_proposal`/
/// `questionnaire_prompt` — проверено `ls`, см. handoff) — сверка идёт
/// напрямую с реальным payload, не с файлом-источником правды. Отдельная
/// эскалация оркестратору, не блокирует эту модель.
///
/// Разбор defensive: любое несоответствие ОБЯЗАТЕЛЬНЫМ полям бросает
/// FormatException — вызывающий код (SduiBlockDispatcher) обязан ловить
/// это и уходить в UnknownBlock. Тот же паттерн, что и
/// calendar_proposal_models.dart/questionnaire_prompt_models.dart.
library;

class CalendarEventConfirmationEvent {
  final String id;
  final String title;
  final String start;
  final String end;

  const CalendarEventConfirmationEvent({
    required this.id,
    required this.title,
    required this.start,
    required this.end,
  });

  factory CalendarEventConfirmationEvent.fromJson(Map<String, dynamic> json) {
    final id    = json['id'];
    final title = json['title'];
    final start = json['start'];
    final end   = json['end'];
    if (id is! String || title is! String || start is! String || end is! String) {
      throw const FormatException(
          'event.id/title/start/end обязательны и должны быть строками');
    }
    return CalendarEventConfirmationEvent(
      id: id,
      title: title,
      start: start,
      end: end,
    );
  }
}

/// ⚠ НАЙДЕНО ЖИВЫМ PAYLOAD (не гипотеза — реальный баг, пойманный до
/// прода): `previous` в реальном ответе backend содержит ТОЛЬКО
/// `start`/`end`, БЕЗ `id`/`title`. Первая версия этого файла ошибочно
/// переиспользовала `CalendarEventConfirmationEvent` целиком (требующий
/// все 4 поля) для `previous` — на реальном, полностью КОРРЕКТНОМ
/// `rescheduled`-блоке это бросило бы FormatException (нет `id`/`title`
/// у `previous`) и деградировало бы ВЕСЬ блок в UnknownBlock, хотя перенос
/// прошёл успешно. Исправлено введением узкого типа специально для
/// `previous` — не копировать структуру `event` бездумно туда, где
/// реальный контракт её не требует.
class CalendarEventTimeRange {
  final String start;
  final String end;

  const CalendarEventTimeRange({required this.start, required this.end});

  factory CalendarEventTimeRange.fromJson(Map<String, dynamic> json) {
    final start = json['start'];
    final end   = json['end'];
    if (start is! String || end is! String) {
      throw const FormatException(
          'previous.start/end обязательны и должны быть строками');
    }
    return CalendarEventTimeRange(start: start, end: end);
  }
}

/// Известные значения `action` по BRIEF. Неизвестное значение — НЕ ошибка
/// парсинга (сервер мог уйти вперёд клиента версией контракта в рамках
/// той же v1) — деградация до нейтрального рендера, забота виджета, не
/// парсинга. Тот же принцип, что и `SduiQuestion.isKnownType` в
/// questionnaire_prompt_models.dart.
const kKnownConfirmationActions = {'cancelled', 'rescheduled'};

class CalendarEventConfirmationBlockData {
  final String action;
  final CalendarEventConfirmationEvent event;
  final CalendarEventTimeRange? previous;

  const CalendarEventConfirmationBlockData({
    required this.action,
    required this.event,
    this.previous,
  });

  bool get isKnownAction => kKnownConfirmationActions.contains(action);

  factory CalendarEventConfirmationBlockData.fromJson(Map<String, dynamic> json) {
    final action   = json['action'];
    final rawEvent = json['event'];
    if (action is! String || rawEvent is! Map) {
      throw const FormatException('action/event обязательны');
    }
    final event = CalendarEventConfirmationEvent.fromJson(
        Map<String, dynamic>.from(rawEvent));

    final rawPrevious = json['previous'];
    CalendarEventTimeRange? previous;
    if (rawPrevious is Map) {
      previous = CalendarEventTimeRange.fromJson(
          Map<String, dynamic>.from(rawPrevious));
    }
    // ✅ ПОДТВЕРЖДЕНО backend'ом живым прогоном (MOBILE_HANDOFF_
    // calendar_event_confirmation_dumps.md): `previous` ГАРАНТИРОВАННО
    // не-null при `action: "rescheduled"` — формируется внутри
    // reschedule_event() ДО UPDATE, в той же транзакции, безусловно при
    // успехе. Нет пути, где rescheduled уходит с previous:null. Мягкая
    // деградация ниже (previous остаётся null при нарушении) избыточна
    // для текущих backend-гарантий, но оставлена как defensive code —
    // backend прямо порекомендовал не убирать ("не вредит").
    return CalendarEventConfirmationBlockData(
      action: action,
      event: event,
      previous: previous,
    );
  }
}
