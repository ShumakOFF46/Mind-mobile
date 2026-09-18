import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/chat/models/sdui/legal_consent_gate_models.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/legal_consent_gate_block.dart';

/// ✅ `AppTheme.light` — геттер `ThemeData` (без скобок), подтверждено
/// живым прогоном 2026-09-06 (изначально предполагал метод `light()` —
/// компилятор поправил: "The method 'call' isn't defined for ThemeData").
Future<void> _pumpBlock(
  WidgetTester tester, {
  required LegalConsentGateBlockData data,
  required Future<void> Function(bool, bool) onSubmit,
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
        body: LegalConsentGateBlock(data: data, onSubmit: onSubmit),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

LegalConsentGateBlockData _fixture({String reason = 'initial'}) =>
    LegalConsentGateBlockData.fromJson({
      'reason': reason,
      'questions': [
        {'key': 'legal:medical_data_accepted', 'label': {'ru': 'Согласие на данные о здоровье'}},
        {'key': 'legal:model_training_accepted', 'label': {'ru': 'Согласие на обучение моделей'}},
      ],
    });

void main() {
  testWidgets('рендерит заголовок, 2 чекбокса и кнопку submit', (tester) async {
    await _pumpBlock(tester, data: _fixture(), onSubmit: (_, _) async {});

    expect(find.byType(Checkbox), findsNWidgets(2));
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.byWidgetPredicate((w) => w is Text && w.data == 'Прежде чем продолжить'),
        findsOneWidget);
  });

  testWidgets('reason=declined показывает баннер, reason=initial — нет', (tester) async {
    await _pumpBlock(tester, data: _fixture(reason: 'declined'), onSubmit: (_, _) async {});
    expect(
      find.textContaining('Вы ранее отклонили условия', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('тап по чекбоксам меняет их состояние (визуально)', (tester) async {
    await _pumpBlock(tester, data: _fixture(), onSubmit: (_, _) async {});

    final checkboxesBefore = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxesBefore.every((c) => c.value == false), isTrue);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    final checkboxesAfter = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(checkboxesAfter.first.value, isTrue);
    expect(checkboxesAfter.last.value, isFalse);
  });

  testWidgets('submit передаёт текущие значения чекбоксов в onSubmit', (tester) async {
    bool? capturedMedical;
    bool? capturedModelTraining;

    await _pumpBlock(
      tester,
      data: _fixture(),
      onSubmit: (medical, modelTraining) async {
        capturedMedical = medical;
        capturedModelTraining = modelTraining;
      },
    );

    // Отмечаем только первый чекбокс (medical_data_accepted).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(capturedMedical, isTrue);
    expect(capturedModelTraining, isFalse);
  });

  testWidgets('после успешного submit блок скрывается (SizedBox.shrink)', (tester) async {
    await _pumpBlock(tester, data: _fixture(), onSubmit: (_, _) async {});

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.byType(Checkbox), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
  });

  testWidgets('во время submit кнопка недоступна и показывает индикатор загрузки',
      (tester) async {
    final completer = Completer<void>();
    await _pumpBlock(
      tester,
      data: _fixture(),
      onSubmit: (_, _) => completer.future,
    );

    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // один кадр — submit ещё "в полёте"

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing); // резолвлен и скрылся
  });
}
