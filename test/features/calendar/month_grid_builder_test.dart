import 'package:flutter_test/flutter_test.dart';
// Заменить на реальное имя пакета из pubspec.yaml (name: ...)
import 'package:vb_mobile/features/calendar/utils/month_grid_builder.dart';

void main() {
  group('buildMonthGrid', () {
    test('месяц не начинается с воскресенья — ведущие пустые ячейки (Aug 2026, старт в Sa)', () {
      final weeks = buildMonthGrid(DateTime(2026, 8));
      final firstWeek = weeks.first;

      expect(firstWeek.sublist(0, 6), everyElement(isNull));
      expect(firstWeek[6], DateTime(2026, 8, 1));
    });

    test('неполная последняя неделя — замыкающие пустые ячейки (Aug 2026)', () {
      final weeks = buildMonthGrid(DateTime(2026, 8));
      final lastWeek = weeks.last;

      expect(lastWeek[0], DateTime(2026, 8, 30)); // воскресенье
      expect(lastWeek[1], DateTime(2026, 8, 31)); // понедельник
      expect(lastWeek.sublist(2), everyElement(isNull));
    });

    test('все дни месяца присутствуют ровно один раз, без дублей/пропусков', () {
      final weeks = buildMonthGrid(DateTime(2026, 8));
      final days = weeks.expand((w) => w).whereType<DateTime>().toList();

      expect(days.length, 31);
      expect(
        days.map((d) => d.day).toSet(),
        List.generate(31, (i) => i + 1).toSet(),
      );
    });
  });
}
