import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/chat/models/sdui/profiling_question_models.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/profiling_question_block.dart';

Future<void> _pumpBlock(
  WidgetTester tester, {
  required ProfilingQuestionBlockData data,
  void Function(String text)? onSendMessage,
  required Future<void> Function(String, String, String) onSubmitAnswer,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ProfilingQuestionBlock(
          data: data,
          onSendMessage: onSendMessage ?? (_) {},
          onSubmitAnswer: onSubmitAnswer,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

ProfilingQuestionBlockData _fixture({int optionsCount = 3, bool isRevalidation = false}) {
  const allOptions = [
    {'label': {'ru': 'Да', 'en': 'Yes'}, 'value': 'yes'},
    {'label': {'ru': 'Нет', 'en': 'No'}, 'value': 'no'},
    {'label': {'ru': 'Не уверена', 'en': 'Not sure'}, 'value': 'unsure'},
    {'label': {'ru': '4'}, 'value': 'v4'},
    {'label': {'ru': '5'}, 'value': 'v5'},
    {'label': {'ru': '6'}, 'value': 'v6'},
  ];
  return ProfilingQuestionBlockData.fromJson({
    'type': 'profiling_question',
    'questionnaire_slug': 'profile_health',
    'answer_key': 'restriction:pregnancy',
    'label': {'ru': 'Вы беременны?', 'en': 'Are you pregnant?'},
    'options': allOptions.take(optionsCount).toList(),
    'is_revalidation': isRevalidation,
  });
}

void main() {
  testWidgets('рендерит блок с 2 опциями (нижняя граница схемы)',
      (tester) async {
    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 2),
      onSubmitAnswer: (_, _, _) async {},
    );
    expect(find.text('Вы беременны?'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsNWidgets(2));
    expect(find.text('Да'), findsOneWidget);
    expect(find.text('Нет'), findsOneWidget);
  });

  testWidgets('рендерит блок с 6 опциями (верхняя граница схемы)',
      (tester) async {
    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 6),
      onSubmitAnswer: (_, _, _) async {},
    );
    expect(find.byType(OutlinedButton), findsNWidgets(6));
  });

  testWidgets('is_revalidation=true показывает подсказку', (tester) async {
    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 2, isRevalidation: true),
      onSubmitAnswer: (_, _, _) async {},
    );
    expect(find.text('Ты уже отвечала на это — давай уточним ещё раз'),
        findsOneWidget);
  });

  testWidgets(
      'успешный тап: вызывает onSubmitAnswer с (slug, answer_key, value), '
      'блокирует остальные кнопки, отправляет подтверждение в чат',
      (tester) async {
    String? capturedSlug, capturedKey, capturedValue;
    String? sentToChat;

    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 3),
      onSendMessage: (t) => sentToChat = t,
      onSubmitAnswer: (slug, key, value) async {
        capturedSlug = slug;
        capturedKey = key;
        capturedValue = value;
      },
    );

    await tester.tap(find.text('Да'));
    await tester.pumpAndSettle();

    expect(capturedSlug, 'profile_health');
    expect(capturedKey, 'restriction:pregnancy');
    expect(capturedValue, 'yes');
    // Решение мобильного агента (см. profiling_question_block.dart,
    // класс-doc): после успешной записи отправляется локализованный текст
    // выбранного варианта как обычное сообщение чата.
    expect(sentToChat, 'Да');

    // Остальные кнопки заблокированы после ответа (isLocked==true).
    final noButton = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('Нет'), matching: find.byType(OutlinedButton)),
    );
    expect(noButton.onPressed, isNull);
  });

  testWidgets(
      'ошибка записи: показывает нейтральную ошибку, кнопки ОСТАЮТСЯ активными '
      'для повторного тапа (BRIEF, "Обработка ошибки")', (tester) async {
    var attempts = 0;

    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 2),
      onSubmitAnswer: (_, _, _) async {
        attempts++;
        throw Exception('network error');
      },
    );

    await tester.tap(find.text('Да'));
    await tester.pumpAndSettle();

    expect(attempts, 1);
    expect(find.text('Не получилось сохранить ответ, попробуй ещё раз'),
        findsOneWidget);

    // Кнопки НЕ заблокированы — можно повторить тап (ключевое отличие от
    // legal_consent_gate/calendar_proposal, где блок считается "отвеченным"
    // независимо от исхода).
    final yesButton = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('Да'), matching: find.byType(OutlinedButton)),
    );
    expect(yesButton.onPressed, isNotNull);

    // Повторный тап после ошибки — новый вызов onSubmitAnswer доходит.
    await tester.tap(find.text('Да'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });

  testWidgets('во время запроса кнопки недоступны, показан индикатор загрузки',
      (tester) async {
    final completer = Completer<void>();
    await _pumpBlock(
      tester,
      data: _fixture(optionsCount: 2),
      onSubmitAnswer: (_, _, _) => completer.future,
    );

    await tester.tap(find.text('Да'));
    await tester.pump(); // один кадр — запрос ещё "в полёте"

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final yesButton = tester.widget<OutlinedButton>(
      find.ancestor(of: find.text('Да'), matching: find.byType(OutlinedButton)),
    );
    expect(yesButton.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });
}
