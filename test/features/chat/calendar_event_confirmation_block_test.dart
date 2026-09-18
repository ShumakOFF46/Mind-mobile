import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/calendar_event_confirmation_block.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/sdui_block_dispatcher.dart';

/// Тесты calendar_event_confirmation v1 (Флоу 4, аддендум
/// BRIEF_mobile_flow4_calendar_event_confirmation.md,
/// CONTRACT_flow4_scheduling_v1.md §4a).
///
/// ✅ Фикстуры `cancelled`/`rescheduled` (test/fixtures/
/// calendar_event_confirmation.mock.json) СВЕРЕНЫ с реальным
/// `agent.messages.blocks` (MOBILE_HANDOFF_calendar_event_confirmation_
/// dumps.md) — два дампа через полный agentic loop, не придуманы.
/// `invalid_version`/`malformed_missing_title`/
/// `malformed_missing_previous_fields` остаются синтетическими
/// edge-cases. См. `_readme` в самом файле фикстур.
///
/// Урок из calendar_proposal_block_test.dart (см.
/// REPORT_mobile_flow4_scheduling_harness.md §4.5): `AppLocalizations.
/// delegate.load()` асинхронна — обязателен `await tester.pump()` после
/// `pumpWidget()` перед любым `find.text(...)`, применено сразу здесь,
/// не по факту первого падения.
void main() {
  late Map<String, dynamic> fixtures;

  setUpAll(() {
    final raw = File('test/fixtures/calendar_event_confirmation.mock.json')
        .readAsStringSync();
    fixtures = jsonDecode(raw) as Map<String, dynamic>;
  });

  Map<String, dynamic> fixture(String key) =>
      Map<String, dynamic>.from(fixtures[key] as Map);

  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        // ⚠ Явно фиксирую 24-часовой формат — TimeOfDay.format(context)
        // (используется внутри _formatInstant()) зависит от
        // MediaQuery.alwaysUse24HourFormat, дефолт которого в тестовом
        // окружении не гарантирован (риск получить "6:00 PM" вместо
        // "18:00" и сломать сравнение строк без связи с логикой виджета).
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
        home: Scaffold(body: child),
      );

  // Блок неинтерактивен по контракту (BRIEF §3: "НЕ тапабельный, никаких
  // колбэков не принимает и не требует") — dispatcher.build() всё ещё
  // требует onSendMessage/onAcceptSlot по сигнатуре (общей для всех
  // блоков), но calendar_event_confirmation их игнорирует. Если бы
  // виджет их всё-таки вызвал — fail() ниже это выявит.
  void Function(String) failOnSendMessage() => (text) =>
      fail('calendar_event_confirmation не должен вызывать onSendMessage, получено: "$text"');
  Future<void> Function(String, String) failOnAcceptSlot() =>
      (session, slot) async =>
          fail('calendar_event_confirmation не должен вызывать onAcceptSlot');
  // Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md §6) — тот
  // же принцип: calendar_event_confirmation неинтерактивен по контракту
  // §4a, поэтому НИ ОДИН из трёх структурированных колбэков не должен
  // вызываться, включая новый onSubmitMedicalConsent.
  Future<void> Function(bool, bool) failOnSubmitMedicalConsent() =>
      (medicalAccepted, modelTrainingAccepted) async =>
          fail('calendar_event_confirmation не должен вызывать onSubmitMedicalConsent');

  testWidgets(
    'calendar_event_confirmation v1 — cancelled: событие показано, действие читаемо',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('cancelled'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(find.text('Отменено'), findsOneWidget);
      expect(find.text('test_confirmation_block_cancel'), findsOneWidget);
      expect(find.text('9 Сен · 16:00'), findsOneWidget);
    },
  );

  testWidgets(
    'calendar_event_confirmation v1 — rescheduled: previous → event оба видны, title не дублируется',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('rescheduled'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(find.text('Перенесено'), findsOneWidget);
      expect(find.text('test_confirmation_block_reschedule'), findsOneWidget); // ровно один раз
      expect(find.text('Было: '), findsOneWidget);
      expect(find.text('10 Сен · 14:00'), findsOneWidget); // previous.start
      expect(find.text('Стало: '), findsOneWidget);
      expect(find.text('11 Сен · 18:00'), findsOneWidget); // event.start
    },
  );

  testWidgets(
    'calendar_event_confirmation — неподдерживаемая версия блока (не 1) деградирует в UnknownBlock, не падает',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('invalid_version'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Пилинг'), findsNothing);
    },
  );

  testWidgets(
    'calendar_event_confirmation — malformed (нет event.title) деградирует в UnknownBlock, не падает',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('malformed_missing_title'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Отменено'), findsNothing);
    },
  );

  testWidgets(
    'calendar_event_confirmation — malformed previous (нет end) деградирует в UnknownBlock, не падает',
    (tester) async {
      // ⚠ Покрывает CalendarEventTimeRange.fromJson() отдельно от
      // CalendarEventConfirmationEvent.fromJson() — узкий тип для
      // previous введён именно потому, что реальный payload требует
      // другой набор обязательных полей (start/end, без id/title), см.
      // calendar_event_confirmation_models.dart.
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('malformed_missing_previous_fields'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Перенесено'), findsNothing);
    },
  );

  testWidgets(
    'calendar_event_confirmation v1 — КРИТИЧНО: блок подтверждённо неинтерактивен (нет ни одного тапабельного элемента)',
    (tester) async {
      await tester.pumpWidget(wrap(SduiBlockDispatcher.build(
        fixture('rescheduled'),
        onSendMessage: failOnSendMessage(),
        onAcceptSlot: failOnAcceptSlot(),
        onSubmitMedicalConsent: failOnSubmitMedicalConsent(),
        onSubmitProfilingAnswer: (_, _, _) async {},
      )));
      await tester.pump();

      // ⚠ Проверка СКОПИРОВАНА до поддерева самого блока, а не всего
      // дерева MaterialApp/Scaffold — Scaffold сам создаёт внутренний
      // RawGestureDetector (тап по статус-бару, "scroll to top" на iOS-
      // манер) напрямую, минуя публичный GestureDetector. Первая версия
      // теста проверяла от корня и ловила ЭТОТ фреймворковый детектор
      // как ложное срабатывание — не имеет отношения к
      // CalendarEventConfirmationBlock. Найдено реальным прогоном, не
      // предположением.
      final block = find.byType(CalendarEventConfirmationBlock);
      expect(block, findsOneWidget);

      // Ни одного из стандартных тапабельных виджетов Flutter внутри
      // самого блока — не "выглядит некликабельно", а действительно НЕТ
      // элемента, который отреагировал бы на тап.
      expect(find.descendant(of: block, matching: find.byType(GestureDetector)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(InkWell)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(InkResponse)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(ElevatedButton)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(OutlinedButton)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(TextButton)),
          findsNothing);
      expect(find.descendant(of: block, matching: find.byType(IconButton)),
          findsNothing);

      // Дополнительно — внутри блока не должно быть ни одного активного
      // жестового распознавателя вообще (страхует от кастомных решений
      // мимо стандартных виджетов), но СТРОГО в его поддереве, не выше.
      expect(
        find.descendant(
          of: block,
          matching: find.byWidgetPredicate((w) => w is RawGestureDetector),
        ),
        findsNothing,
      );
    },
  );
}
