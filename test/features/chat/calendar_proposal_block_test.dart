import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/sdui_block_dispatcher.dart';

/// Тесты calendar_proposal v2 (Флоу 4, CONTRACT_flow4_scheduling_v1.md).
///
/// ✅ Фикстуры `with_candidates`/`round_2_of_3` (test/fixtures/
/// calendar_proposal.mock.json) СВЕРЕНЫ с реальным `agent.messages.blocks`
/// (REPORT_backend_flow4_mobile_verification_response.md, 2026-09-03,
/// scheduling_session_id=7ebbb8af-3e92-482c-a69e-2d15e4b13a90) — не
/// придуманы. `single_candidate`/`empty_candidates`/`invalid_version`/
/// `malformed_missing_fields` остаются синтетическими edge-cases (живого
/// эквивалента по своей природе не имеют/не требуют), см. `_readme` в
/// самом файле фикстур.
///
/// ⚠ Не видел существующий `questionnaire_prompt_block_test.dart` — если
/// в проекте уже есть общий helper для pumpWidget/локализации в тестах,
/// предпочесть его этому self-contained `_wrap()` ради консистентности
/// (не в объёме этой правки, файла не было в контексте).
void main() {
  late Map<String, dynamic> fixtures;

  setUpAll(() {
    final raw = File('test/fixtures/calendar_proposal.mock.json').readAsStringSync();
    fixtures = jsonDecode(raw) as Map<String, dynamic>;
  });

  Map<String, dynamic> fixture(String key) =>
      Map<String, dynamic>.from(fixtures[key] as Map);

  // CalendarProposalBlock вызывает context.l10n.schedulingRoundIndicator()
  // напрямую в build() — без делегатов AppLocalizations pumpWidget упадёт
  // на null-check, а не на логической ошибке теста.
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

  testWidgets(
    'calendar_proposal v2 — рендерит кандидатов, round-индикатор и reject_label из payload',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('with_candidates'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      // AppLocalizations.delegate.load() асинхронна (даже без внутренних
      // await) — Flutter не резолвит локаль за один pumpWidget(), без
      // этого кадра дерево виджетов ещё не содержит локализованный текст.
      await tester.pump();

      expect(find.text('Попытка 1 из 3'), findsOneWidget);
      expect(find.text('Среда, 15:00'), findsOneWidget);
      expect(find.text('Четверг, 15:00'), findsOneWidget);
      expect(find.text('Пятница, 15:00'), findsOneWidget);
      expect(find.text('Ни одно не подходит'), findsOneWidget);
    },
  );

  testWidgets(
    'calendar_proposal v2 — round/round_cap рендерятся из payload второго раунда, не хардкод',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('round_2_of_3'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(find.text('Попытка 2 из 3'), findsOneWidget);
    },
  );

  testWidgets(
    'calendar_proposal v2 — КРИТИЧНО: тап по кандидату уходит в onAcceptSlot с правильными id, НЕ в onSendMessage',
    (tester) async {
      String? sentText;
      String? acceptedSession;
      String? acceptedSlot;

      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('with_candidates'),
        onSendMessage: (t) => sentText = t,
        onAcceptSlot: (session, slot) async {
          acceptedSession = session;
          acceptedSlot = slot;
        },
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      await tester.tap(find.text('Среда, 15:00'));
      await tester.pump();

      expect(acceptedSlot, 's1');
      expect(acceptedSession, '7ebbb8af-3e92-482c-a69e-2d15e4b13a90');
      expect(sentText, isNull,
          reason: 'тап по кандидату НЕ должен уходить в чат текстом (CONTRACT §1,§3)');
    },
  );

  testWidgets(
    'calendar_proposal v2 — тап по reject_label уходит в onSendMessage (quick-reply), НЕ в onAcceptSlot',
    (tester) async {
      String? sentText;
      bool acceptCalled = false;

      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('with_candidates'),
        onSendMessage: (t) => sentText = t,
        onAcceptSlot: (_, _) async => acceptCalled = true,
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      await tester.tap(find.text('Ни одно не подходит'));
      await tester.pump();

      expect(sentText, 'Ни одно не подходит');
      expect(acceptCalled, isFalse);
    },
  );

  testWidgets(
    'calendar_proposal v2 — во время ожидания ответа на accept повторный тап не дублирует вызов',
    (tester) async {
      var acceptCallCount = 0;
      final completer = Completer<void>();

      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('with_candidates'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {
          acceptCallCount++;
          await completer.future;
        },
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      await tester.tap(find.text('Среда, 15:00'));
      await tester.pump();
      // Второй тап тем же кадром, пока onAcceptSlot ещё не завершился —
      // кнопки должны быть задизейблены (_isProcessing).
      await tester.tap(find.text('Среда, 15:00'), warnIfMissed: false);
      await tester.pump();

      expect(acceptCallCount, 1);
      completer.complete();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'calendar_proposal — неподдерживаемая версия блока (не 2) деградирует в UnknownBlock, не падает',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('invalid_version'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Вторник, 18:00'), findsNothing);
    },
  );

  testWidgets(
    'calendar_proposal — malformed (нет round_cap) деградирует в UnknownBlock, не падает',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('malformed_missing_fields'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Вторник, 18:00'), findsNothing);
    },
  );

  testWidgets(
    'calendar_proposal — пустой candidates деградирует в UnknownBlock (не рисует пустой список для тапа)',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('empty_candidates'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Ни одно не подходит'), findsNothing);
    },
  );

  testWidgets(
    'calendar_proposal v2 — одиночный кандидат (последний раунд) рендерится корректно',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('single_candidate'),
        onSendMessage: (_) {},
        onAcceptSlot: (_, _) async {},
        onSubmitMedicalConsent: (_, _) async {},
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(find.text('Попытка 3 из 3'), findsOneWidget);
      expect(find.text('Воскресенье, 14:00'), findsOneWidget);
    },
  );
}
