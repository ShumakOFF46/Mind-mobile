import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../models/procedure_event.dart';
import '../utils/category_label.dart';

/// Модальное окно с детальным описанием процедуры. Только просмотр —
/// применение/отклонение/редактирование процедуры (Флоу 4, Phase 3,
/// scheduling_orchestrator.py) ещё не реализовано на бэкенде, поэтому
/// здесь нет ни одной кнопки, имитирующей запись/изменение.
Future<void> showProcedureDetailSheet(
  BuildContext context,
  ProcedureEvent procedure,
) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => _ProcedureDetailSheet(procedure: procedure),
  );
}

class _ProcedureDetailSheet extends StatelessWidget {
  final ProcedureEvent procedure;
  const _ProcedureDetailSheet({required this.procedure});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;
    final time = TimeOfDay.fromDateTime(procedure.dateTime).format(context);
    final dateLabel =
        '${procedure.dateTime.day} ${l.monthShortLabels[procedure.dateTime.month - 1]}';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.hint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: procedure.category.dotColor,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  categoryLabel(procedure.category, l),
                  style: TextStyle(color: c.textSub, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              procedure.title,
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                color: c.textDark,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 14, color: c.textSub),
                const SizedBox(width: 6),
                Text('$dateLabel · $time',
                    style: TextStyle(color: c.textSub, fontSize: 13)),
                if (procedure.durationMinutes != null) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.timer_outlined, size: 14, color: c.textSub),
                  const SizedBox(width: 6),
                  Text(l.procedureDetailDuration(procedure.durationMinutes!),
                      style: TextStyle(color: c.textSub, fontSize: 13)),
                ],
              ],
            ),
            if (procedure.notes != null) ...[
              const SizedBox(height: 20),
              Text(
                l.procedureDetailAbout,
                style: TextStyle(
                  color: c.textDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                procedure.notes!,
                style: TextStyle(color: c.textSub, fontSize: 14, height: 1.5),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: c.hint),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l.procedureDetailClose,
                  style: TextStyle(color: c.textDark, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
