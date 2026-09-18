import 'package:flutter/material.dart';

/// ✅ Добавлен член `other` (Step 0 fix, BRIEF_mobile_flow4_scheduling_
/// harness.md) — подтверждённый факт, не гипотеза: `CalendarEvent.category`
/// на бэкенде (routers/app_calendar.py) — свободная строка с дефолтом
/// `"skincare"`, которого среди исходных 4 членов не было. `other` —
/// явный, видимый в UI бакет для любой backend-категории, не совпадающей
/// с serum/mask/eyeCare/peel по имени (см. calendar_events_provider.dart
/// ::_resolveCategory()), вместо прежнего молчаливого/вводящего в
/// заблуждение фолбэка на `serum`.
enum ProcedureCategory { serum, mask, eyeCare, peel, other }

extension ProcedureCategoryColor on ProcedureCategory {
  /// Цвет точки-индикатора категории на сетке/таймлайне (см. концепт).
  /// Отдельная от theme.dart палитра — не глобальные токены приложения,
  /// а per-category акценты, специфичные для этой фичи.
  Color get dotColor {
    switch (this) {
      case ProcedureCategory.serum:
        return const Color(0xFFE8A0A0);
      case ProcedureCategory.mask:
        return const Color(0xFFE06A6A);
      case ProcedureCategory.eyeCare:
        return const Color(0xFF7EA8C9);
      case ProcedureCategory.peel:
        return const Color(0xFFB08AC9);
      case ProcedureCategory.other:
        // Нейтральный оттенок из уже существующей палитры AURA
        // (theme.dart: textSub light #9E7E7E) — не новый акцентный цвет,
        // намеренно "невыразительный", чтобы визуально не претендовать
        // на принадлежность к конкретной категории ухода.
        return const Color(0xFF9E7E7E);
    }
  }
}

class ProcedureEvent {
  final String id;
  final String title;
  final DateTime dateTime;
  final ProcedureCategory category;

  /// Свободный текст описания процедуры — зеркалит `beauty.calendar_events.
  /// notes` (см. ProjectFull.md), чтобы форма модели не менялась при
  /// переключении с моков на реальный getCalendarEvents().
  final String? notes;

  /// Зеркалит `beauty.calendar_events.duration_minutes` / `scheduling_meta.
  /// duration_minutes` (universal_dialog_engine.md §2, «Формат процедуры»).
  final int? durationMinutes;

  const ProcedureEvent({
    required this.id,
    required this.title,
    required this.dateTime,
    required this.category,
    this.notes,
    this.durationMinutes,
  });
}
