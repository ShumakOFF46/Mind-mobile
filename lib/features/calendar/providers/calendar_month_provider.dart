import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Текущий отображаемый месяц календаря — локальный UI-state, БЕЗ похода
/// в API (навигация ‹/› не завязана на реальные данные, см. брифа
/// «вне объёма» — иначе потом придётся откатывать).
/// autoDispose осознанно: в отличие от calendarBadgeProvider (кэш на
/// время жизни чата), тут состояние логично сбрасывать при каждом заходе
/// на экран.
final calendarDisplayedMonthProvider =
    StateProvider.autoDispose<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
