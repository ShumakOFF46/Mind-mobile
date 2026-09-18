/// Строит сетку дней месяца для календаря Su-Sa.
/// Каждая неделя — ровно 7 элементов; `null` = пустая ведущая/замыкающая
/// ячейка выравнивания (см. BRIEF_mobile_calendar_screen_redesign.md,
/// Вариант B — 1 августа 2026 должно попасть в субботу).
List<List<DateTime?>> buildMonthGrid(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

  // DateTime.weekday: Mon=1..Sun=7. Сетка начинается с воскресенья.
  final leadingEmpty = firstDay.weekday % 7;

  final totalCells = leadingEmpty + daysInMonth;
  final trailingEmpty = (7 - (totalCells % 7)) % 7;

  final cells = <DateTime?>[
    ...List.filled(leadingEmpty, null),
    for (var d = 1; d <= daysInMonth; d++)
      DateTime(month.year, month.month, d),
    ...List.filled(trailingEmpty, null),
  ];

  return [
    for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
  ];
}
