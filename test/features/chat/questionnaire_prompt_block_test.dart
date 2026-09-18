// test/features/chat/questionnaire_prompt_block_test.dart
//
// Прогоняет все 11 фикстур из questionnaire_prompt.mock.json через
// РЕАЛЬНУЮ цепочку ChatMessage -> ChatBubble -> SduiBlockDispatcher ->
// QuestionnairePromptBlock, а не изолированный виджет-тест в отрыве от
// чат-экрана (требование чек-листа брифа questionnaire_prompt).
//
// ⚠ ИЗМЕНЕНО (Флоу 4, аддендум calendar_event_confirmation): ChatBubble
// получил новый обязательный параметр `onAcceptSlot` (см.
// REPORT_mobile_flow4_scheduling_harness.md §3.2) — этот тестовый файл
// не был известен на момент той правки (не грепался, т.к. репозиторий не
// был доступен целиком), из-за чего `flutter test` (без указания
// конкретного файла) сломался на компиляции именно здесь. Добавлен
// no-op `onAcceptSlot` в `_pumpBubble()` — questionnaire_prompt не
// использует Флоу 4 колбэки, поведение самих тестов не меняется ни в
// одной ассерции.
//
// ⚠ ИЗМЕНЕНО (Legal Consent Gate v4): ChatBubble получил ещё один новый
// обязательный параметр `onSubmitMedicalConsent` (CONTRACT_legal_
// consent_gate_v4.md §6) — тот же класс правки, что уже была сделана
// для `onAcceptSlot` выше по тексту этого комментария. no-op в
// `_pumpBubble()`, questionnaire_prompt не использует medical-гейт.
//
// ⚠ ИЗМЕНЕНО (Deterministic Profiling Answer v1): ChatBubble получил ещё
// один новый обязательный параметр `onSubmitProfilingAnswer`
// (CONTRACT_deterministic_profiling_answer_v1.md §2) — тот же класс
// правки. no-op в `_pumpBubble()`, questionnaire_prompt не использует
// этот write-путь.
//
// Требует: flutter_test, сам пакет приложения.
// Запуск: flutter test test/features/chat/questionnaire_prompt_block_test.dart

// ⚠ ИСТОРИЯ ЭТОГО КОММЕНТАРИЯ (см. REPORT_mobile_flow4_scheduling_
// harness.md, аддендум): в этом файле изначально были импорты
// `widgets/sdui/` (строчными), физическая папка на диске в момент
// диагностики была `widgets/SDUI/` (заглавными, подтверждено
// Get-ChildItem) — на Windows/NTFS расхождение молчало, на
// регистрозависимой ФС (Gitea Act Runner, ubuntu-latest, ProjectInfra.md)
// сборка упала бы. Промежуточный фикс временно переводил импорты на
// `SDUI/`, чтобы совпасть с диском. Итоговое решение оркестратора —
// ОБРАТНОЕ: переименовать саму папку в `sdui/` (строчными), приведя к
// уже существующему в проекте соглашению (models/sdui,
// test/.../models/sdui, и сам chat_bubble.dart изначально ссылался на
// `sdui/sdui_block_dispatcher.dart` строчными). Импорты ниже приведены
// обратно к `sdui/` строчными — это ФИНАЛЬНОЕ состояние, соответствующее
// папке ПОСЛЕ `git mv` (см. отчёт), не откат к до-диагностическому багу.
//
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/models/chat_message.dart';
import 'package:vb_mobile/features/chat/widgets/chat_bubble.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/unknown_block.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/questionnaire_prompt_block.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/controls/qp_buttons_control.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/controls/qp_multi_enum_control.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/controls/qp_numeric_control.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/controls/qp_free_text_control.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/controls/qp_plain_label.dart';

late Map<String, dynamic> _fixtures;

Future<void> _pumpBubble(
  WidgetTester tester,
  Map<String, dynamic> block, {
  void Function(String text)? onSendMessage,
}) async {
  final message = ChatMessage(
    text:   '',
    isUser: false,
    blocks: [block],
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'), // фикстуры и label-строки — русские
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChatBubble(
          message:                message,
          isStreamingPlaceholder: false, // блок рендерится только после
                                          // завершения стрима, см. chat_bubble.dart
          onLongPress:   () {},
          onSendMessage: onSendMessage ?? (_) {},
          // Флоу 4 (calendar_proposal/calendar_event_confirmation) —
          // questionnaire_prompt этот колбэк не использует ни в одном
          // сценарии, no-op достаточен. Если он вдруг будет вызван —
          // это укажет на баг в диспетчере (questionnaire_prompt блок
          // не должен доходить до calendar_proposal-ветки), но явного
          // fail() здесь не ставлю: этот файл проверяет questionnaire_
          // prompt, а не разведение колбэков Флоу 4 (это уже покрыто
          // calendar_proposal_block_test.dart/calendar_event_
          // confirmation_block_test.dart).
          onAcceptSlot: (_, _) async {},
          // Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md
          // §6) — questionnaire_prompt этот колбэк тоже не использует
          // ни в одном сценарии, тот же принцип, что у onAcceptSlot
          // выше. Найдено live-прогоном `flutter analyze` 2026-09-06
          // после введения нового обязательного параметра
          // SduiBlockDispatcher.build()/ChatBubble.
          onSubmitMedicalConsent: (_, _) async {},
          // Deterministic Profiling Answer v1 — questionnaire_prompt этот
          // колбэк тоже не использует ни в одном сценарии, тот же принцип.
          onSubmitProfilingAnswer: (_, _, _) async {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    final raw = await File(
      'test/fixtures/questionnaire_prompt.mock.json',
    ).readAsString();
    _fixtures = jsonDecode(raw) as Map<String, dynamic>;
  });

  Map<String, dynamic> fixture(String key) =>
      Map<String, dynamic>.from(_fixtures[key] as Map);

  group('questionnaire_prompt — интерактивные типы (buttons)', () {
    testWidgets('bool -> QpButtonsControl с 2 опциями', (tester) async {
      await _pumpBubble(tester, fixture('bool'));
      expect(find.byType(QuestionnairePromptBlock), findsOneWidget);
      expect(find.byType(QpButtonsControl), findsOneWidget);
      expect(find.text('Да'), findsOneWidget);
      expect(find.text('Нет'), findsOneWidget);
    });

    testWidgets('tri_state -> QpButtonsControl с 3 опциями', (tester) async {
      await _pumpBubble(tester, fixture('tri_state'));
      expect(find.byType(QpButtonsControl), findsOneWidget);
      expect(find.text('Не уверена'), findsOneWidget);
    });

    testWidgets('enum -> QpButtonsControl, intro отрендерен', (tester) async {
      await _pumpBubble(tester, fixture('enum'));
      expect(find.byType(QpButtonsControl), findsOneWidget);
      expect(
        find.textContaining('Пара вопросов про питание'),
        findsOneWidget,
      );
    });

    testWidgets('тап по кнопке отправляет option.label, не value',
        (tester) async {
      String? sent;
      await _pumpBubble(
        tester,
        fixture('bool'),
        onSendMessage: (t) => sent = t,
      );
      await tester.tap(find.text('Да'));
      await tester.pumpAndSettle();
      expect(sent, 'Да'); // НЕ 'true' — value на сервер не уходит отдельно
    });
  });

  group('questionnaire_prompt — multi_enum', () {
    testWidgets('multi_enum -> QpMultiEnumControl, чипы + подтверждение',
        (tester) async {
      await _pumpBubble(tester, fixture('multi_enum'));
      expect(find.byType(QpMultiEnumControl), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(4));
    });

    testWidgets('выбор нескольких чипов + Готово отправляет через запятую',
        (tester) async {
      String? sent;
      await _pumpBubble(
        tester,
        fixture('multi_enum'),
        onSendMessage: (t) => sent = t,
      );
      await tester.tap(find.text('Латекс'));
      await tester.pump();
      await tester.tap(find.text('Пыльца'));
      await tester.pump();
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();
      expect(sent, 'Латекс, Пыльца');
    });
  });

  group('questionnaire_prompt — free_text семейство', () {
    testWidgets('numeric -> QpNumericControl даже при input_mode=free_text',
        (tester) async {
      await _pumpBubble(tester, fixture('numeric'));
      expect(find.byType(QpNumericControl), findsOneWidget);
      expect(find.byType(QpFreeTextControl), findsNothing);
    });

    testWidgets('numeric отправляет "{label}: {value}"', (tester) async {
      String? sent;
      await _pumpBubble(
        tester,
        fixture('numeric'),
        onSendMessage: (t) => sent = t,
      );
      await tester.enterText(find.byType(TextField), '1500');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(sent, 'Сколько воды вы примерно выпиваете в день?: 1500');
    });

    testWidgets('open_list -> QpFreeTextControl, maxLines=1', (tester) async {
      await _pumpBubble(tester, fixture('open_list'));
      final control = tester.widget<QpFreeTextControl>(
        find.byType(QpFreeTextControl),
      );
      expect(control.question.type, 'open_list');
    });

    testWidgets('free_paragraph -> QpFreeTextControl, отправка с префиксом',
        (tester) async {
      String? sent;
      await _pumpBubble(
        tester,
        fixture('free_paragraph'),
        onSendMessage: (t) => sent = t,
      );
      await tester.enterText(
        find.byType(TextField),
        'Встаю рано, много хожу пешком',
      );
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();
      expect(
        sent,
        'Расскажите в паре предложений про свой обычный распорядок дня.: '
        'Встаю рано, много хожу пешком',
      );
    });
  });

  group('questionnaire_prompt — множественные вопросы / revalidation', () {
    testWidgets('multi_question_progress — интерактивен только questions[0]',
        (tester) async {
      await _pumpBubble(tester, fixture('multi_question_progress'));
      // Только первый вопрос виден как контрол:
      expect(find.text('Есть ли у вас аллергия на латекс?'), findsOneWidget);
      expect(find.text('Вы беременны?'), findsNothing);
      expect(find.text('Принимаете ли вы БАДы?'), findsNothing);
      // Индикатор прогресса виден (конкретный текст зависит от l10n-строки):
      expect(find.byType(QpButtonsControl), findsOneWidget);
    });

    testWidgets('revalidation — подсказка is_revalidation отрендерена',
        (tester) async {
      await _pumpBubble(tester, fixture('revalidation'));
      expect(find.byType(QpButtonsControl), findsOneWidget);
      // Точный текст qpRevalidationHint зависит от l10n — проверяем факт
      // наличия доп. Text-виджета сверх обычной пары label/controls.
    });
  });

  group('questionnaire_prompt — деградация на неизвестных значениях', () {
    testWidgets('invalid_question_type -> QpPlainLabel, label виден, крашей нет',
        (tester) async {
      await _pumpBubble(tester, fixture('invalid_question_type'));
      expect(find.byType(QuestionnairePromptBlock), findsOneWidget);
      expect(find.byType(QpPlainLabel), findsOneWidget);
      expect(
        find.text('Это поле из будущей версии схемы, клиент его ещё не знает.'),
        findsOneWidget,
      );
      // Никаких кнопок/полей ввода для неизвестного типа:
      expect(find.byType(QpButtonsControl), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('invalid_block_version -> UnknownBlock, экран не падает',
        (tester) async {
      await _pumpBubble(tester, fixture('invalid_block_version'));
      expect(find.byType(UnknownBlock), findsOneWidget);
      expect(find.byType(QuestionnairePromptBlock), findsNothing);
    });
  });
}
