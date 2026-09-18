import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/models/sdui/questionnaire_prompt_models.dart';
import 'package:vb_mobile/features/chat/widgets/SDUI/questionnaire_prompt_block.dart';
import 'package:vb_mobile/features/chat/widgets/SDUI/controls/qp_malformed_banner.dart';
import 'package:vb_mobile/features/chat/widgets/SDUI/controls/qp_buttons_control.dart';

// ⚠ Замените 'package:vb_mobile/...' на реальное имя пакета из pubspec.yaml,
// если оно отличается.

void main() {
  Widget wrap(Widget child) => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('SduiQuestion.isMalformedButtonsWithoutOptions', () {
    test('options: [] (empty array) is detected as malformed', () {
      // ⚠ Это регрессионный тест на реальный баг: до фикса (сессия
      // 2026-08-31) проверка ловила только options == null, "options": []
      // проходил мимо неё (rawOptions is List истинно и для []).
      final json = {
        'answer_key': 'symptom:itching',
        'type': 'tri_state',
        'input_mode': 'buttons',
        'label': 'Есть зуд в этой области?',
        'options': <dynamic>[],
      };

      final question = SduiQuestion.fromJson(json);

      expect(question.isMalformedButtonsWithoutOptions, isTrue);
      expect(question.isInteractive, isFalse);
    });

    test('missing options key (null) is still detected as malformed', () {
      final json = {
        'answer_key': 'symptom:itching',
        'type': 'tri_state',
        'input_mode': 'buttons',
        'label': 'Есть зуд в этой области?',
      };

      final question = SduiQuestion.fromJson(json);

      expect(question.isMalformedButtonsWithoutOptions, isTrue);
    });

    test('valid options is NOT flagged as malformed', () {
      final json = {
        'answer_key': 'symptom:itching',
        'type': 'tri_state',
        'input_mode': 'buttons',
        'label': 'Есть зуд в этой области?',
        'options': [
          {'value': 'yes', 'label': 'Да'},
          {'value': 'no', 'label': 'Нет'},
        ],
      };

      final question = SduiQuestion.fromJson(json);

      expect(question.isMalformedButtonsWithoutOptions, isFalse);
      expect(question.isInteractive, isTrue);
    });

    test('free_text input_mode with empty options is NOT malformed '
        '(options not required outside buttons)', () {
      final json = {
        'answer_key': 'profile:health:notes',
        'type': 'free_paragraph',
        'input_mode': 'free_text',
        'label': 'Расскажи подробнее',
        'options': <dynamic>[],
      };

      final question = SduiQuestion.fromJson(json);

      expect(question.isMalformedButtonsWithoutOptions, isFalse);
      expect(question.isInteractive, isTrue);
    });
  });

  group('QuestionnairePromptBlock malformed rendering', () {
    testWidgets(
      'malformed question[0] hides label/progress/control, shows banner only',
      (tester) async {
        final data = QuestionnairePromptBlockData(
          blockVersion: 1,
          questionnaireSlug: 'profile_health',
          intro: 'Немного уточнений',
          questions: [
            SduiQuestion.fromJson({
              'answer_key': 'symptom:itching',
              'type': 'tri_state',
              'input_mode': 'buttons',
              'label': 'Есть зуд в этой области?',
              'options': <dynamic>[],
            }),
          ],
        );

        await tester.pumpWidget(wrap(
          QuestionnairePromptBlock(data: data, onSendMessage: (_) {}),
        ));
        // Доп. pump: MaterialApp.localizationsDelegates резолвит локаль
        // асинхронно (delegate.load() возвращает Future) — без этого
        // Localizations не успевает смонтировать дочернее дерево на первом
        // кадре, finder не находит ничего вообще, включая intro-текст,
        // никак не связанный с локализацией. Подтверждено живым прогоном
        // (flutter test): без доп. pump все 3 widget-теста падали с
        // "Found 0 widgets" даже для plain-text intro.
        await tester.pump();

        // intro (заголовок блока) виден как обычно.
        expect(find.text('Немного уточнений'), findsOneWidget);
        // баннер вместо контрола.
        expect(find.byType(QpMalformedBanner), findsOneWidget);
        // label вопроса не рендерится.
        expect(find.text('Есть зуд в этой области?'), findsNothing);
        // контрол не рендерится.
        expect(find.byType(QpButtonsControl), findsNothing);
      },
    );

    testWidgets(
      'valid question[0] renders as before (regression guard)',
      (tester) async {
        final data = QuestionnairePromptBlockData(
          blockVersion: 1,
          questionnaireSlug: 'profile_health',
          intro: null,
          questions: [
            SduiQuestion.fromJson({
              'answer_key': 'symptom:itching',
              'type': 'tri_state',
              'input_mode': 'buttons',
              'label': 'Есть зуд в этой области?',
              'options': [
                {'value': 'yes', 'label': 'Да'},
                {'value': 'no', 'label': 'Нет'},
              ],
            }),
          ],
        );

        await tester.pumpWidget(wrap(
          QuestionnairePromptBlock(data: data, onSendMessage: (_) {}),
        ));
        // Доп. pump: MaterialApp.localizationsDelegates резолвит локаль
        // асинхронно (delegate.load() возвращает Future) — без этого
        // Localizations не успевает смонтировать дочернее дерево на первом
        // кадре, finder не находит ничего вообще, включая intro-текст,
        // никак не связанный с локализацией. Подтверждено живым прогоном
        // (flutter test): без доп. pump все 3 widget-теста падали с
        // "Found 0 widgets" даже для plain-text intro.
        await tester.pump();

        expect(find.byType(QpMalformedBanner), findsNothing);
        expect(find.text('Есть зуд в этой области?'), findsOneWidget);
        expect(find.byType(QpButtonsControl), findsOneWidget);
      },
    );

    testWidgets(
      'malformed question[0] with multiple questions still shows only banner '
      '(questions[1+] never rendered client-side regardless of malformed status, '
      'per existing QuestionnairePromptBlock design)',
      (tester) async {
        final data = QuestionnairePromptBlockData(
          blockVersion: 1,
          questionnaireSlug: 'profile_health',
          intro: null,
          questions: [
            SduiQuestion.fromJson({
              'answer_key': 'symptom:itching',
              'type': 'tri_state',
              'input_mode': 'buttons',
              'label': 'Есть зуд в этой области?',
              'options': <dynamic>[],
            }),
            SduiQuestion.fromJson({
              'answer_key': 'symptom:duration_days',
              'type': 'enum',
              'input_mode': 'buttons',
              'label': 'Сколько дней это уже есть?',
              'options': [
                {'value': '<3', 'label': 'Меньше 3 дней'},
                {'value': '3-14', 'label': '3–14 дней'},
              ],
            }),
          ],
        );

        await tester.pumpWidget(wrap(
          QuestionnairePromptBlock(data: data, onSendMessage: (_) {}),
        ));
        // Доп. pump: MaterialApp.localizationsDelegates резолвит локаль
        // асинхронно (delegate.load() возвращает Future) — без этого
        // Localizations не успевает смонтировать дочернее дерево на первом
        // кадре, finder не находит ничего вообще, включая intro-текст,
        // никак не связанный с локализацией. Подтверждено живым прогоном
        // (flutter test): без доп. pump все 3 widget-теста падали с
        // "Found 0 widgets" даже для plain-text intro.
        await tester.pump();

        expect(find.byType(QpMalformedBanner), findsOneWidget);
        expect(find.text('Сколько дней это уже есть?'), findsNothing);
      },
    );
  });
}
