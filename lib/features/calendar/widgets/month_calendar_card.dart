import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';
import '../providers/calendar_month_provider.dart';
import '../utils/month_grid_builder.dart';
import 'calendar_day_cell.dart';

/// Карточка месяца: ‹ Month YYYY › + строка дней недели + сетка дат.
/// Навигация — чисто локальный state (см. calendar_month_provider.dart).
class MonthCalendarCard extends ConsumerWidget {
  final List<ProcedureEvent> procedures;

  const MonthCalendarCard({super.key, required this.procedures});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.aura;
    final l = context.l10n;
    final month = ref.watch(calendarDisplayedMonthProvider);
    final weeks = buildMonthGrid(month);
    final today = DateTime.now();

    final datesWithProcedures = procedures
        .map((p) =>
            DateTime(p.dateTime.year, p.dateTime.month, p.dateTime.day))
        .toSet();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left_rounded, color: c.textSub),
                onPressed: () => ref
                    .read(calendarDisplayedMonthProvider.notifier)
                    .update((m) => DateTime(m.year, m.month - 1)),
              ),
              Text(
                l.monthYearLabel(month),
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.textDark,
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right_rounded, color: c.textSub),
                onPressed: () => ref
                    .read(calendarDisplayedMonthProvider.notifier)
                    .update((m) => DateTime(m.year, m.month + 1)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final label in l.weekdayShortLabels)
                Expanded(
                  child: Center(
                    child: Text(label,
                        style: TextStyle(color: c.textSub, fontSize: 12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          for (final week in weeks)
            Row(
              children: [
                for (final date in week)
                  Expanded(
                    child: CalendarDayCell(
                      date: date,
                      isToday: date != null &&
                          date.year == today.year &&
                          date.month == today.month &&
                          date.day == today.day,
                      hasProcedure:
                          date != null && datesWithProcedures.contains(date),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
