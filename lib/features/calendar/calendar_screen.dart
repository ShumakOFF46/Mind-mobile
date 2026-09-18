import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/l10n/app_localizations.dart';
import 'providers/calendar_events_provider.dart';
import 'providers/calendar_month_provider.dart';
import 'widgets/month_calendar_card.dart';
import 'widgets/today_section.dart';
import 'widgets/upcoming_procedures_section.dart';

/// Beauty Plan — календарь процедур. Сетка месяца интерактивна (‹/›,
/// локальный state).
///
/// ✅ Step 0 fix (BRIEF_mobile_flow4_scheduling_harness.md, п.0): список
/// процедур — реальные данные через [calendarEventsProvider]
/// (GET /app/calendar/events), mockAugust2026Procedures() здесь больше не
/// вызывается. Рефетч при каждом открытии экрана — за счёт
/// `autoDispose` провайдера (см. providers/calendar_events_provider.dart),
/// не RouteObserver (CONTRACT_flow4_scheduling_v1.md §5).
///
/// ⚠ Мэппинг JSON→ProcedureEvent в calendar_events_provider.dart помечен
/// как НЕ сверенный с живым ответом бэкенда — см. отчёт оркестратору,
/// не выдавать этот экран за полностью подтверждённый до отдельной
/// сверки.
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final l = context.l10n;
    final month = ref.watch(calendarDisplayedMonthProvider);
    final eventsAsync = ref.watch(calendarEventsProvider);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: c.textDark),
          onPressed: () => context.pop(),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.calendarTitle,
              style: const TextStyle(
                fontFamily: 'CormorantGaramond',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 3,
              ),
            ),
            Text(
              l.monthYearLabel(month),
              style: TextStyle(color: c.textSub, fontSize: 11),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: eventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) {
            debugPrint('calendarEventsProvider error: $err');
            return _CalendarLoadError(
              // Переиспользую уже существующий generic-ключ ошибок
              // (core/l10n/app_localizations.dart) вместо добавления
              // нового — не плодить локализационные ключи там, где
              // существующий подходит по смыслу.
              message: l.errorGeneric,
              onRetry: () => ref.invalidate(calendarEventsProvider),
            );
          },
          data: (procedures) => ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              MonthCalendarCard(procedures: procedures),
              const SizedBox(height: 16),
              TodaySection(procedures: procedures),
              const SizedBox(height: 16),
              UpcomingProceduresSection(procedures: procedures),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarLoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _CalendarLoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: TextStyle(color: c.textSub)),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Icon(Icons.refresh_rounded, color: c.textDark),
          ),
        ],
      ),
    );
  }
}
