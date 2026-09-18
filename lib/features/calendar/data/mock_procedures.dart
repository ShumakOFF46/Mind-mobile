import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';

/// Тестовые моки для визуального рефакторинга calendar_screen.dart.
/// НЕ подключать getCalendarEvents() взамен этого списка — backend-часть
/// планирования (Флоу 4, Phase 3, scheduling_orchestrator.py) ещё не
/// реализована, см. BRIEF_mobile_calendar_screen_redesign.md.
///
/// Принимает `AppLocalizations`, а не хардкодит строки: в реальном
/// контракте бэкенда название/описание процедуры приходит уже разрешённым
/// под язык текущего хода (label_resolver, см. ProjectFull.md/
/// universal_dialog_engine.md) — моки должны вести себя так же, иначе
/// поведение локализации в проде и на моках расходится.
///
/// ⚠ Осознанное решение: сами названия брендов/процедур (HydraGlow Serum,
/// Overnight Sleep Mask...) оставлены одинаковыми во всех локалях — как и
/// названия косметических средств в реальных вертикалях, они, как
/// правило, не переводятся. Переведены и полностью локализованы
/// описания (`notes`). Если продукт ожидает перевод и самих названий —
/// нужно отдельное решение, это не техническое ограничение.
List<ProcedureEvent> mockAugust2026Procedures(AppLocalizations l) => [
      ProcedureEvent(
        id: 'mock-1',
        title: l.mockProcedureHydraGlowSerumTitle,
        dateTime: DateTime(2026, 8, 20, 8, 0),
        category: ProcedureCategory.serum,
        notes: l.mockProcedureHydraGlowSerumNotes,
        durationMinutes: 10,
      ),
      ProcedureEvent(
        id: 'mock-2',
        title: l.mockProcedureOvernightSleepMaskTitle,
        dateTime: DateTime(2026, 8, 21, 22, 0),
        category: ProcedureCategory.mask,
        notes: l.mockProcedureOvernightSleepMaskNotes,
        durationMinutes: 15,
      ),
      ProcedureEvent(
        id: 'mock-3',
        title: l.mockProcedureRetinolEyeSerumTitle,
        dateTime: DateTime(2026, 8, 22, 21, 0),
        category: ProcedureCategory.eyeCare,
        notes: l.mockProcedureRetinolEyeSerumNotes,
        durationMinutes: 5,
      ),
      ProcedureEvent(
        id: 'mock-4',
        title: l.mockProcedureLacticAcidPeelTitle,
        dateTime: DateTime(2026, 8, 24, 20, 0),
        category: ProcedureCategory.peel,
        notes: l.mockProcedureLacticAcidPeelNotes,
        durationMinutes: 20,
      ),
      ProcedureEvent(
        id: 'mock-5',
        title: l.mockProcedureHydraGlowSerumTitle,
        dateTime: DateTime(2026, 8, 26, 8, 0),
        category: ProcedureCategory.serum,
        notes: l.mockProcedureHydraGlowSerumNotes,
        durationMinutes: 10,
      ),
    ];
