import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/profiling_question_block.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/sdui_block_dispatcher.dart';
import 'package:vb_mobile/features/chat/widgets/sdui/unknown_block.dart';

/// Диспетчер-уровень: SduiBlockDispatcher.build(type: 'profiling_question')
/// -> UnknownBlock при контрактном нарушении, экран чата не падает.
/// (BRIEF_mobile_deterministic_profiling_answer.md, чек-лист приёмки:
/// "Виджет-тест на UnknownBlock-fallback при отсутствии обязательного поля
/// (например answer_key)".)

Map<String, dynamic> _validBlock() => {
      'type': 'profiling_question',
      'questionnaire_slug': 'profile_health',
      'answer_key': 'restriction:pregnancy',
      'label': {'ru': 'Вы беременны?', 'en': 'Are you pregnant?'},
      'options': [
        {'label': {'ru': 'Да', 'en': 'Yes'}, 'value': 'yes'},
        {'label': {'ru': 'Нет', 'en': 'No'}, 'value': 'no'},
      ],
      'is_revalidation': false,
    };

Future<void> _pumpDispatched(WidgetTester tester, Map<String, dynamic> block) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SduiBlockDispatcher.build(
          block,
          onSendMessage: (_) {},
          onAcceptSlot: (_, _) async {},
          onSubmitMedicalConsent: (_, _) async {},
          onSubmitProfilingAnswer: (_, _, _) async {},
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('валидный блок диспетчеризуется в ProfilingQuestionBlock',
      (tester) async {
    await _pumpDispatched(tester, _validBlock());
    expect(find.byType(ProfilingQuestionBlock), findsOneWidget);
    expect(find.byType(UnknownBlock), findsNothing);
  });

  testWidgets('отсутствие answer_key -> UnknownBlock, экран не падает',
      (tester) async {
    final block = _validBlock()..remove('answer_key');
    await _pumpDispatched(tester, block);
    expect(find.byType(UnknownBlock), findsOneWidget);
    expect(find.byType(ProfilingQuestionBlock), findsNothing);
  });

  testWidgets('отсутствие label -> UnknownBlock, экран не падает',
      (tester) async {
    final block = _validBlock()..remove('label');
    await _pumpDispatched(tester, block);
    expect(find.byType(UnknownBlock), findsOneWidget);
  });

  testWidgets('options[] с 1 элементом (< minItems=2) -> UnknownBlock',
      (tester) async {
    final block = _validBlock();
    block['options'] = [
      {'label': {'ru': 'Да'}, 'value': 'yes'},
    ];
    await _pumpDispatched(tester, block);
    expect(find.byType(UnknownBlock), findsOneWidget);
  });

  testWidgets('незнакомый type -> UnknownBlock (регрессия базового диспетчера)',
      (tester) async {
    await _pumpDispatched(tester, {'type': 'totally_unknown_block'});
    expect(find.byType(UnknownBlock), findsOneWidget);
  });
}
