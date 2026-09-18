import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Одна ячейка сетки: число дня, акцент для "сегодня", точка-индикатор
/// наличия процедуры. `date == null` — пустая ячейка выравнивания недели.
class CalendarDayCell extends StatelessWidget {
  final DateTime? date;
  final bool isToday;
  final bool hasProcedure;

  const CalendarDayCell({
    super.key,
    required this.date,
    required this.isToday,
    required this.hasProcedure,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final d = date;
    if (d == null) return const SizedBox(height: 44);

    return SizedBox(
      height: 44,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isToday ? c.accent : Colors.transparent,
            ),
            child: Text(
              '${d.day}',
              style: TextStyle(
                color: isToday ? Colors.white : c.textDark,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: 4,
            height: 4,
            child: hasProcedure
                ? DecoratedBox(
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: c.accent),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
