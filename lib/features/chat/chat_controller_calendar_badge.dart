import 'package:flutter/foundation.dart';

/// BRIEF_mobile_calendar_badge_invalidation_gap.md — единственная точка,
/// где ChatController сигнализирует "список записей календаря мог
/// измениться" наружу. Вынесено миксином в отдельный файл, чтобы не
/// раздувать chat_controller.dart (правило ≤300-400 строк, файл и так
/// был на границе — 393 строки до этого брифа) — тот же принцип, что и
/// extension'ы chat_controller_legal_consent.dart/
/// chat_controller_profiling_answer.dart, но здесь нужен именно `mixin`,
/// не `extension`: extension'ы не могут объявлять instance-поля, а
/// [onCalendarChanged] — поле, не метод.
///
/// ChatController — обычный ChangeNotifier, без доступа к Riverpod `ref`
/// (единственный прежде существовавший триггер бейджа был колбэком в
/// chat_screen.dart, у которого `ref` есть — см. doc
/// calendar_badge_provider.dart и коммит 35ab43f, где этот колбэк удалили
/// вместе с мёртвым кодом `_applyCalendarProposalSilently`). Подписчик
/// (chat_screen.dart, `ConsumerState`) обязан присвоить сюда
/// `() => ref.invalidate(calendarBadgeProvider)` в `initState` —
/// контроллер сам ничего не знает про Riverpod-провайдер, только
/// вызывает колбэк после событий, которые реально меняют
/// `beauty.calendar_events` на бэкенде.
mixin ChatControllerCalendarBadge on ChangeNotifier {
  /// Вызывается из ChatController после подтверждённого приёма слота
  /// (`acceptSchedulingSlot`, status == "confirmed") и после прихода
  /// блока `calendar_event_confirmation` (cancel/reschedule,
  /// `_appendBlocksToLastMessage`) — оба пути из
  /// BRIEF_mobile_calendar_badge_invalidation_gap.md п.1.2.
  VoidCallback? onCalendarChanged;
}
