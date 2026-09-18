import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';
import '../utils/category_label.dart';
import 'procedure_detail_sheet.dart';

class TodaySection extends StatelessWidget {
  final List<ProcedureEvent> procedures;
  const TodaySection({super.key, required this.procedures});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final today = DateTime.now();
    final todays = procedures
        .where((p) =>
            p.dateTime.year == today.year &&
            p.dateTime.month == today.month &&
            p.dateTime.day == today.day)
        .toList();

    if (todays.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(l.calendarToday,
                  style: TextStyle(
                      fontFamily: 'CormorantGaramond',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: c.textDark)),
              const SizedBox(width: 6),
              Text(l.calendarProcedureCount(todays.length),
                  style: TextStyle(color: c.textSub, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          for (final p in todays) _TodayTile(procedure: p),
        ],
      ),
    );
  }
}

class _TodayTile extends StatelessWidget {
  final ProcedureEvent procedure;
  const _TodayTile({required this.procedure});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final time = TimeOfDay.fromDateTime(procedure.dateTime).format(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showProcedureDetailSheet(context, procedure),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: procedure.category.dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.water_drop_outlined,
                      color: procedure.category.dotColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(procedure.title,
                          style: TextStyle(
                              color: c.textDark,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                      Text('$time · ${categoryLabel(procedure.category, l)}',
                          style: TextStyle(color: c.textSub, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, border: Border.all(color: c.hint)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
