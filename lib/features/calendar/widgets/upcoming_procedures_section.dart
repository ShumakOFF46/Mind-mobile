import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';
import '../utils/category_label.dart';
import 'procedure_detail_sheet.dart';

class UpcomingProceduresSection extends StatelessWidget {
  final List<ProcedureEvent> procedures;
  const UpcomingProceduresSection({super.key, required this.procedures});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final sorted = [...procedures]
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration:
          BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.calendarUpcomingProcedures,
              style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: c.textDark)),
          const SizedBox(height: 12),
          for (final p in sorted) _TimelineTile(procedure: p),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final ProcedureEvent procedure;
  const _TimelineTile({required this.procedure});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final time = TimeOfDay.fromDateTime(procedure.dateTime).format(context);
    final monthAbbr =
        l.monthShortLabels[procedure.dateTime.month - 1].toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showProcedureDetailSheet(context, procedure),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: procedure.category.dotColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(monthAbbr,
                          style: TextStyle(
                              color: procedure.category.dotColor,
                              fontSize: 9,
                              height: 1.1,
                              fontWeight: FontWeight.w700)),
                      Text('${procedure.dateTime.day}',
                          style: TextStyle(
                              color: c.textDark,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                      color: c.aiBubble, borderRadius: BorderRadius.circular(14)),
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
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: procedure.category.dotColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
