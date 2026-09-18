// test/features/chat/calendar_proposal_channel_routing_test.dart
//
// BRIEF_mobile_calendar_proposal_transport_fix.md, п.3.1/3.2 +
// ADDENDUM_mobile_calendar_proposal_transport_fix.md, "Аддендум 2"
// (work/flow4_calendar_proposal_silent_nonrender/ в vb_docs).
//
// ДО ФИКСА (35ab43f): SSE-поле `{"calendar_proposal": {...}}` уходило в
// мёртвый устаревший passthrough-обработчик (ждал ключ `events`, которого
// в v2-блоке нет — там `candidates`) — `messages.last.blocks` оставался
// `null`, экран пустой, независимо от содержимого блока. Backend
// (app_chat.py::_split_blocks(), BRIEF §2.1) СОЗНАТЕЛЬНО никогда не
// кладёт calendar_proposal в generic `blocks[]` — только в это отдельное
// поле. Полный разбор — REPORT_mobile_calendar_proposal_render_check.md.
//
// ПОСЛЕ ФИКСА: `ChatController.handleStreamEvent()` обрабатывает
// `calendar_proposal` через тот же путь, что и `blocks[]` —
// `_appendBlocksToLastMessage()` — блок мёрджится в `message.blocks` и
// доходит до `SduiBlockDispatcher`/`CalendarProposalBlock`.
//
// ⚠ ФИКСТУРЫ — byte-exact, не реконструкция (п.3.2 брифа закрыт этой
// правкой). Раньше здесь использовалась реконструированная фикстура
// (calendar_proposal_live_trace_2026_09_14.mock.json, по агрегированным
// полям backend-отчёта) — заменена на два файла, доставленных backend'ом
// и подтверждённых оркестратором как byte-exact дамп реальных сообщений
// живого трейса (`REPORT_backend_calendar_proposal_fix.md` п.2,
// `ADDENDUM_mobile_calendar_proposal_transport_fix.md`, "Аддендум 2"):
//   - test/fixtures/calendar_proposal_live_241168f8.wire.json
//     = дословная копия calendar_proposal_message_14e50bfa_session_
//       241168f8.wire.json — round 1/3, session 241168f8, 18:00 Пн/Вт/Ср
//       (21–23 сентября 2026), "правильный" блок живого трейса.
//   - test/fixtures/calendar_proposal_live_c6dfcc17.wire.json
//     = дословная копия calendar_proposal_message_2f61e65b_session_
//       c6dfcc17.wire.json — round 3/3, session c6dfcc17, 15:00 Пн/Вт/Ср
//       (те же три дня), "чужой" блок, на который реально попал
//       пользователь (backend-баг get_proposing_session_by_owner(),
//       параллельный, не решающий для немоты экрана — см. read.me задачи).
// Оба файла — ИМЕННО `.wire.json`-вариант (compact, `\uXXXX`-escaped),
// не pretty-`.json` — по указанию аддендума: `.wire.json` byte-exact тому,
// что реально шлёт backend по SSE, pretty-версия только для читаемости
// при ревью. Файлы копируются как есть, без правок (в т.ч. без `_readme`
// внутри JSON) — иначе байт-точность теряет смысл.
//
// Каждый файл на верхнем уровне уже имеет форму `{"calendar_proposal":
// {...}}` — ровно ту, что приходит по реальному SSE, поэтому для
// ChatController-теста файл используется целиком как event, а для
// widget-теста берётся вложенный `['calendar_proposal']` как сам блок.
//
// Первая группа тестов — виджет-уровень (SduiBlockDispatcher напрямую):
// подтверждает, что оба реальных блока рендерятся корректно, а пустой
// candidates рендерит специализированное состояние
// CalendarProposalEmptyBlock, а не generic UnknownBlock.
//
// Вторая группа — уровень ChatController: те же события, доставленные
// РОВНО тем каналом, которым их реально доставляет `app_chat.py`, теперь
// ДОХОДЯТ до `messages.last.blocks` — прямая проверка фикса. Плюс
// regression на мёрдж `blocks` + `calendar_proposal` в одном сообщении и
// regression на `calendar_event_confirmation` (канал `blocks[]`).
//
// ⚠ Реальный прогон `flutter test` в этой сессии НЕ выполнен — Flutter
// toolchain отсутствует в песочнице агента. Файл нужно прогнать локально
// (PowerShell на машине Mobile) — см. REPORT_mobile_calendar_proposal_
// transport_fix.md для инструкции и открытых хвостов (живой прогон на
// эмуляторе/устройстве, п.3.3 брифа, тоже не подменяется этим файлом).

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/chat_controller.dart';
import 'package:vb_mobile/features/chat/models/chat_message.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/calendar_proposal_block.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/sdui_block_dispatcher.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/unknown_block.dart';

Stream<Map<String, dynamic>> _neverUsedStreamChat({
  required String prompt,
  String? conversationId,
  List<Map<String, dynamic>>? busySlots,
}) async* {
  throw UnimplementedError('не используется — handleStreamEvent() вызывается напрямую');
}

void main() {
  // Полное декодированное SSE-событие {"calendar_proposal": {...}}, как
  // оно реально приходит с backend — используется напрямую в
  // handleStreamEvent().
  late Map<String, dynamic> event241168f8;
  late Map<String, dynamic> eventC6dfcc17;

  setUpAll(() {
    event241168f8 = jsonDecode(
      File('test/fixtures/calendar_proposal_live_241168f8.wire.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
    eventC6dfcc17 = jsonDecode(
      File('test/fixtures/calendar_proposal_live_c6dfcc17.wire.json')
          .readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  // Сам блок (без обёртки {"calendar_proposal": ...}) — то, что реально
  // рендерит SduiBlockDispatcher.build().
  Map<String, dynamic> block241168f8() =>
      Map<String, dynamic>.from(event241168f8['calendar_proposal'] as Map);
  Map<String, dynamic> blockC6dfcc17() =>
      Map<String, dynamic>.from(eventC6dfcc17['calendar_proposal'] as Map);

  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('Виджет-уровень — оба byte-exact живых блока рендерятся, пустой '
      'candidates даёт специализированное состояние', () {
    testWidgets('Проверка 1 (241168f8, round 1/3, 18:00 Пн/Вт/Ср) — рендерится',
        (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        block241168f8(),
        onSendMessage: (_) {},
        onAcceptSlot: (_, __) async {},
        onSubmitMedicalConsent: (_, __) async {},
        onSubmitProfilingAnswer: (_, __, ___) async {},
      )));
      await tester.pump();

      expect(find.text('Попытка 1 из 3'), findsOneWidget);
      expect(find.text('Понедельник, 18:00'), findsOneWidget);
      expect(find.text('Вторник, 18:00'), findsOneWidget);
      expect(find.text('Среда, 18:00'), findsOneWidget);
    });

    testWidgets('Проверка 2 (c6dfcc17, round 3/3, 15:00 Пн/Вт/Ср) — рендерится',
        (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        blockC6dfcc17(),
        onSendMessage: (_) {},
        onAcceptSlot: (_, __) async {},
        onSubmitMedicalConsent: (_, __) async {},
        onSubmitProfilingAnswer: (_, __, ___) async {},
      )));
      await tester.pump();

      expect(find.text('Попытка 3 из 3'), findsOneWidget);
      expect(find.text('Понедельник, 15:00'), findsOneWidget);
      expect(find.text('Вторник, 15:00'), findsOneWidget);
      expect(find.text('Среда, 15:00'), findsOneWidget);
    });

    testWidgets(
      'П.2 брифа — пустой candidates рендерит CalendarProposalEmptyBlock, '
      'НЕ generic UnknownBlock',
      (tester) async {
        final emptyBlock = {
          ...block241168f8(),
          'candidates': <Map<String, dynamic>>[],
        };

        await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
          emptyBlock,
          onSendMessage: (_) {},
          onAcceptSlot: (_, __) async {},
          onSubmitMedicalConsent: (_, __) async {},
          onSubmitProfilingAnswer: (_, __, ___) async {},
        )));
        await tester.pump();

        expect(find.byType(CalendarProposalEmptyBlock), findsOneWidget);
        expect(find.byType(UnknownBlock), findsNothing);
      },
    );
  });

  group('ChatController-уровень — фикс маршрутизации SSE-поля '
      '{"calendar_proposal": {...}}, byte-exact события', () {
    test(
      'Проверка 1 (241168f8) — messages.last.blocks ТЕПЕРЬ содержит блок',
      () async {
        final controller = ChatController(streamChat: _neverUsedStreamChat);
        controller.messages.add(ChatMessage(text: '', isUser: false));

        await controller.handleStreamEvent(event241168f8);

        expect(
          controller.messages.last.blocks,
          isNotNull,
          reason: 'До фикса ChatController._applyCalendarProposalSilently() '
              'ждал ключ "events" (старый passthrough-контракт) и молча '
              'выходил на v2-блоке. После фикса calendar_proposal идёт '
              'через тот же _appendBlocksToLastMessage(), что и blocks[].',
        );
        expect(controller.messages.last.blocks, hasLength(1));
        expect(
          controller.messages.last.blocks!.first['scheduling_session_id'],
          '241168f8-a7ed-4687-ae92-c2b6b841df3b',
        );
      },
    );

    test(
      'Проверка 2 (c6dfcc17) — тот же результат, независимо от '
      'корректности сессии (баг был в канале доставки, не в содержимом)',
      () async {
        final controller = ChatController(streamChat: _neverUsedStreamChat);
        controller.messages.add(ChatMessage(text: '', isUser: false));

        await controller.handleStreamEvent(eventC6dfcc17);

        expect(controller.messages.last.blocks, isNotNull);
        expect(controller.messages.last.blocks, hasLength(1));
        expect(
          controller.messages.last.blocks!.first['scheduling_session_id'],
          'c6dfcc17-ced2-426a-ae31-621962215cd5',
        );
      },
    );

    test(
      'Regression — {"blocks": [...]} (канал calendar_event_confirmation) '
      'продолжает работать без изменений после рефакторинга',
      () async {
        final controller = ChatController(streamChat: _neverUsedStreamChat);
        controller.messages.add(ChatMessage(text: '', isUser: false));

        await controller.handleStreamEvent({
          'blocks': [block241168f8()],
        });

        expect(controller.messages.last.blocks, isNotNull);
        expect(controller.messages.last.blocks, hasLength(1));
        expect(
          controller.messages.last.blocks!.first['scheduling_session_id'],
          '241168f8-a7ed-4687-ae92-c2b6b841df3b',
        );
      },
    );

    test(
      'Regression — blocks[] и calendar_proposal на ОДНО сообщение мёрджатся, '
      'а не перезаписывают друг друга',
      () async {
        final controller = ChatController(streamChat: _neverUsedStreamChat);
        controller.messages.add(ChatMessage(text: '', isUser: false));

        await controller.handleStreamEvent({
          'blocks': [block241168f8()],
        });
        await controller.handleStreamEvent(eventC6dfcc17);

        expect(
          controller.messages.last.blocks,
          hasLength(2),
          reason: 'Наивный фикс через copyWith(blocks: [block]) '
              'перезаписал бы первый блок вместо мёрджа — здесь оба '
              'должны сохраниться.',
        );
      },
    );
  });
}
