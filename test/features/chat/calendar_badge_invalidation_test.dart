// test/features/chat/calendar_badge_invalidation_test.dart
//
// BRIEF_mobile_calendar_badge_invalidation_gap.md, п.3.1.
//
// ДО ФИКСА: единственный существовавший триггер `ref.invalidate(
// calendarBadgeProvider)` был колбэком `onCalendarApplied`, завязанным на
// мёртвый passthrough-код `_applyCalendarProposalSilently()`, удалённый
// в BRIEF_mobile_calendar_proposal_transport_fix.md (коммит 35ab43f) —
// после этого бейдж не обновлялся ни для одного реального флоу.
//
// ПОСЛЕ ФИКСА: `ChatController.onCalendarChanged` (mixin
// `ChatControllerCalendarBadge`, см. chat_controller_calendar_badge.dart)
// вызывается из двух путей, которые реально меняют
// `beauty.calendar_events`:
//   - `acceptSchedulingSlot()` при `status: "confirmed"` (calendar_proposal
//     → приём слота, основной кейс из эскалации);
//   - `_appendBlocksToLastMessage()` при приходе блока
//     `calendar_event_confirmation` (cancel/reschedule, канал `blocks[]`).
// Ровно НЕ вызывается на путях, которые ничего не меняют в календаре:
// сам `calendar_proposal` (предложение, ещё не принято), reject-ветка
// `/accept` (`reason`) и сетевая ошибка `/accept`.
//
// ChatController — обычный ChangeNotifier, без `ref` (см. doc
// chat_controller_calendar_badge.dart) — тестируется сам колбэк, а не
// фактический `ref.invalidate` (это делает chat_screen.dart, вне
// Riverpod-контекста unit-теста).
//
// ⚠ Реальный прогон `flutter test` в этой сессии НЕ выполнен — Flutter
// toolchain отсутствует в песочнице агента (см.
// REPORT_mobile_calendar_badge_invalidation_gap.md).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/api/api_client.dart';
import 'package:vb_mobile/features/chat/chat_controller.dart';
import 'package:vb_mobile/features/chat/models/chat_message.dart';
import 'package:vb_mobile/features/chat/models/scheduling_messages.dart';
import '../../helpers/fake_http_client_adapter.dart';

Stream<Map<String, dynamic>> _neverUsedStreamChat({
  required String prompt,
  String? conversationId,
  List<Map<String, dynamic>>? busySlots,
}) async* {
  throw UnimplementedError('не используется — вызываем методы напрямую');
}

const _messages = SchedulingMessages(
  confirmed:    'Запись подтверждена',
  staleRound:   'Раунд устарел',
  notFound:     'Сессия не найдена',
  notOwner:     'Не ваша сессия',
  genericError: 'Ошибка',
);

void main() {
  late Map<String, dynamic> confirmationEvents;

  setUpAll(() {
    confirmationEvents = jsonDecode(
      File('test/fixtures/calendar_event_confirmation.mock.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  Map<String, dynamic> confirmationBlock(String key) =>
      Map<String, dynamic>.from(confirmationEvents[key] as Map);

  group('acceptSchedulingSlot() — п.1.2 основной кейс из эскалации', () {
    test('status: confirmed → onCalendarChanged вызван ровно один раз',
        () async {
      ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
        return const FakeResponse(
          statusCode: 200,
          data: {'status': 'confirmed', 'event_id': 'evt-1'},
        );
      });
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.acceptSchedulingSlot(
        schedulingSessionId: 'sess-1',
        slotId: 'slot-1',
        schedulingMessages: _messages,
      );

      expect(callCount, 1);
    });

    test('status: error (reason: stale_round) → onCalendarChanged НЕ вызван',
        () async {
      ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
        return const FakeResponse(
          statusCode: 200,
          data: {'status': 'error', 'reason': 'stale_round'},
        );
      });
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.acceptSchedulingSlot(
        schedulingSessionId: 'sess-1',
        slotId: 'slot-1',
        schedulingMessages: _messages,
      );

      expect(callCount, 0);
    });

    test('сетевая ошибка /accept → onCalendarChanged НЕ вызван', () async {
      ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
        return const FakeResponse(
          statusCode: 500,
          data: {'detail': 'server error'},
        );
      });
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.acceptSchedulingSlot(
        schedulingSessionId: 'sess-1',
        slotId: 'slot-1',
        schedulingMessages: _messages,
      );

      expect(callCount, 0);
    });
  });

  group('calendar_event_confirmation (blocks[]) — п.1.2 второй путь', () {
    test('action: cancelled → onCalendarChanged вызван', () async {
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      controller.messages.add(ChatMessage(text: '', isUser: false));
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.handleStreamEvent({
        'blocks': [confirmationBlock('cancelled')],
      });

      expect(callCount, 1);
    });

    test('action: rescheduled → onCalendarChanged вызван', () async {
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      controller.messages.add(ChatMessage(text: '', isUser: false));
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.handleStreamEvent({
        'blocks': [confirmationBlock('rescheduled')],
      });

      expect(callCount, 1);
    });

    test(
      'malformed-блок (нет event.title) → onCalendarChanged всё равно '
      'вызван: SduiBlockDispatcher деградирует до UnknownBlock, но '
      'событие на бэкенде уже реально произошло',
      () async {
        final controller = ChatController(streamChat: _neverUsedStreamChat);
        controller.messages.add(ChatMessage(text: '', isUser: false));
        var callCount = 0;
        controller.onCalendarChanged = () => callCount++;

        await controller.handleStreamEvent({
          'blocks': [confirmationBlock('malformed_missing_title')],
        });

        expect(callCount, 1);
      },
    );
  });

  group('Regression — пути, НЕ меняющие календарь, не триггерят колбэк', () {
    test('calendar_proposal (предложение слотов, ещё не принято) → '
        'onCalendarChanged НЕ вызван', () async {
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      controller.messages.add(ChatMessage(text: '', isUser: false));
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.handleStreamEvent({
        'calendar_proposal': {
          'type': 'calendar_proposal',
          'version': 2,
          'candidates': <Map<String, dynamic>>[],
        },
      });

      expect(callCount, 0);
    });

    test('обычный текстовый чанк content → onCalendarChanged НЕ вызван',
        () async {
      final controller = ChatController(streamChat: _neverUsedStreamChat);
      controller.messages.add(ChatMessage(text: '', isUser: false));
      var callCount = 0;
      controller.onCalendarChanged = () => callCount++;

      await controller.handleStreamEvent({'content': 'привет'});

      expect(callCount, 0);
    });
  });
}
