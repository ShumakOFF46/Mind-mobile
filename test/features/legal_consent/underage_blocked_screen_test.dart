import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/legal_consent/underage_blocked_screen.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light, // см. комментарий в legal_consent_gate_block_test.dart
        locale: const Locale('ru'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: const UnderageBlockedScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('показывает заголовок, сообщение и кнопку закрытия', (tester) async {
    await pump(tester);

    expect(find.text('Сервис недоступен'), findsOneWidget);
    expect(
      find.textContaining('доступна только пользователям', findRichText: true),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, 'Закрыть'), findsOneWidget);
  });

  testWidgets('тап по "Закрыть" вызывает SystemNavigator.pop (platform channel)', (tester) async {
    var popCalled = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') popCalled = true;
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await pump(tester);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Закрыть'));
    await tester.pumpAndSettle();

    expect(popCalled, isTrue);
  });

  testWidgets('PopScope блокирует системный back (canPop=false)', (tester) async {
    await pump(tester);
    final popScope = tester.widget<PopScope>(find.byType(PopScope));
    expect(popScope.canPop, isFalse);
  });
}
