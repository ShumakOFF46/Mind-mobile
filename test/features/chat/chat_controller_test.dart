// test/features/chat/chat_controller_test.dart
//
// BRIEF_mobile_fix_conversationid_reset_on_stream_exception.md
//
// Проверяет явную политику из catch-блока ChatController.sendMessage():
// обрыв ApiClient.streamChat() посреди потока (сеть/таймаут) —
//   - conversationId был null до попытки  → остаётся null
//   - conversationId был известен до попытки → НЕ обнуляется
// плюс сам факт логирования обрыва (тип исключения + состояние id).
//
// ApiClient.streamChat() не мокается напрямую (статический метод) —
// вместо этого используется typedef-шов StreamChatFn, инжектируемый
// через конструктор ChatController. ApiClient/SSE-парсинг не тронуты.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vb_mobile/features/chat/chat_controller.dart';

/// Мок-реализация StreamChatFn: всегда рвётся с исключением до того,
/// как успевает отдать хотя бы одно событие (имитация обрыва сети/
/// таймаута посреди потока, как описано в брифе).
Stream<Map<String, dynamic>> _throwingStreamChat({
  required String prompt,
  String? conversationId,
  List<Map<String, dynamic>>? busySlots,
}) async* {
  throw Exception('simulated network drop mid-stream');
}

void main() {
  late List<String> logs;
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    logs = [];
    originalDebugPrint = debugPrint;
    // Перехватываем debugPrint, чтобы проверить пункт 1 брифа
    // (обязательное логирование обрыва) не косвенно, а по факту.
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) logs.add(message);
    };
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  group('sendMessage() — conversationId policy on streamChat() exception', () {
    test(
      'conversationId был null ДО попытки → остаётся null после обрыва '
      '(новый разговор не долетел до сервера, ничего "осиротевшего" не '
      'появляется)',
      () async {
        final controller = ChatController(streamChat: _throwingStreamChat);
        expect(controller.conversationId, isNull);

        await controller.sendMessage(overrideText: 'первое сообщение');

        expect(
          controller.conversationId,
          isNull,
          reason: 'id нового разговора никогда не был получен от сервера — '
              'обнулять было нечего, и присваивать что-либо не следует',
        );
        expect(controller.isStreaming, isFalse);

        // Пункт 1: обрыв обязан быть залогирован с текущим conversationId
        // (null) и типом исключения.
        expect(
          logs.any((l) =>
              l.contains('conversationId остаётся null') &&
              l.contains('Exception')),
          isTrue,
          reason: 'ожидался лог о том, что conversationId сохранён как null',
        );
      },
    );

    test(
      'conversationId был ИЗВЕСТЕН ДО попытки → НЕ обнуляется после обрыва '
      '(разговор на сервере существует, оборвался только content-поток)',
      () async {
        const existingId = 'conv-existing-abc-123';
        final controller = ChatController(streamChat: _throwingStreamChat)
          ..conversationId = existingId;

        await controller.sendMessage(overrideText: 'продолжение диалога');

        expect(
          controller.conversationId,
          equals(existingId),
          reason: 'обнуление потеряло бы связь с реальной перепиской на '
              'сервере — id уже существующего разговора не должен '
              'сбрасываться из-за обрыва content-потока',
        );
        expect(controller.isStreaming, isFalse);

        // Пункт 1: обрыв обязан быть залогирован с текущим conversationId
        // (уже известным) и типом исключения.
        expect(
          logs.any((l) =>
              l.contains(existingId) &&
              l.contains('сохранён') &&
              l.contains('Exception')),
          isTrue,
          reason:
              'ожидался лог о том, что уже известный conversationId сохранён',
        );
      },
    );
  });
}
