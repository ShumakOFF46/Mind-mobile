import 'package:flutter/material.dart';
import '../core/neu/neu_button.dart';
import '../core/neu/neu_surface.dart';
import '../core/theme.dart';

// Тексты захардкожены намеренно: showcase, не продуктовый UI.

/// Кнопка «Календарь» по образцу 3D Sample: выпуклая карточка с номером
/// месяца и подписью, утопленной полосой дней недели, сеткой текущего месяца
/// и подсвеченным сегодняшним числом. Масштабируется по `size` (базовый 132).
class CalendarMiniButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const CalendarMiniButton({super.key, this.onTap, this.size = 132});

  static const _week = ['П', 'В', 'С', 'Ч', 'П', 'С', 'В'];
  static const _w = 114.0; // ширина контента в базовых единицах
  static const _cellH = 13.0;

  /// Ячейки месяца (пн — первый день недели), пустые — `null`.
  static List<List<int?>> weeks(DateTime now) {
    final lead = DateTime(now.year, now.month, 1).weekday - 1;
    final days = DateTime(now.year, now.month + 1, 0).day;
    final cells = <int?>[
      ...List<int?>.filled(lead, null),
      for (var d = 1; d <= days; d++) d,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final now = DateTime.now();
    final k = size / 132;

    return NeuButton(
      width: size,
      height: size,
      radius: 32 * k,
      intensity: 0.8,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(9 * k),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: _w,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${now.month}',
                        style: TextStyle(color: c.textDark, fontSize: 9, fontWeight: FontWeight.w700)),
                    Text('КАЛЕНДАРЬ',
                        style: TextStyle(color: c.textDark, fontSize: 8, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 5),
                NeuSurface(
                  depth: NeuDepth.inset,
                  radius: 6,
                  intensity: 0.25,
                  height: 13,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      for (final d in _week)
                        Text(d, style: TextStyle(color: c.textSub, fontSize: 7, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                for (final week in weeks(now))
                  Row(
                    children: [
                      for (final d in week)
                        SizedBox(
                          width: _w / 7,
                          height: _cellH,
                          child: Center(child: _cell(c, d, d == now.day)),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(AuraColorScheme c, int? d, bool today) {
    if (d == null) return const SizedBox.shrink();
    final text = Text('$d',
        style: TextStyle(
          color: today ? c.bg : c.textDark,
          fontSize: 8,
          fontWeight: today ? FontWeight.w700 : FontWeight.w500,
        ));
    if (!today) return text;
    return Container(
      width: 15,
      height: 12,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: c.accent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: text,
    );
  }
}
