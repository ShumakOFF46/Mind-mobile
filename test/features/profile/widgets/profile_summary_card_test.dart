import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/features/profile/models/profile_summary.dart';
import 'package:vb_mobile/features/profile/widgets/profile_summary_card.dart';

/// BRIEF_mobile_profile_summary.md, чек-лист приёмки: "Все три состояния
/// summary.status визуально проверены". Это покрытие — по смоканным
/// значениям модели, НЕ живой сетевой ответ (живой прогон делается
/// вручную на тестовом аккаунте, см. отчёт сессии).
void main() {
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

  testWidgets('loading=true (первый рендер до ответа) — только skeleton, без текста',
      (tester) async {
    await tester.pumpWidget(wrap(const ProfileSummaryCard(summary: null, loading: true)));
    await tester.pump();

    expect(find.text('AURA ещё формирует описание — загляните чуть позже.'), findsNothing);
  });

  testWidgets('status=ready — показывает summary.text как обычный текст', (tester) async {
    const summary = ProfileSummary(
      completionPercent: 62,
      status: ProfileSummaryStatus.ready,
      text: 'AURA видит вас как человека с комбинированной кожей.',
    );
    await tester.pumpWidget(wrap(const ProfileSummaryCard(summary: summary, loading: false)));
    await tester.pump();

    expect(find.text('AURA видит вас как человека с комбинированной кожей.'), findsOneWidget);
  });

  testWidgets('status=pending — placeholder, без текста саммари', (tester) async {
    const summary = ProfileSummary(
      completionPercent: 10,
      status: ProfileSummaryStatus.pending,
      text: null,
    );
    await tester.pumpWidget(wrap(const ProfileSummaryCard(summary: summary, loading: false)));
    await tester.pump();

    expect(find.text('AURA ещё формирует описание — загляните чуть позже.'), findsOneWidget);
  });

  testWidgets(
      'status=failed с непустым text — показывает предыдущий текст как обычный, '
      'без визуальной пометки ошибки (контракт §4)', (tester) async {
    const summary = ProfileSummary(
      completionPercent: 40,
      status: ProfileSummaryStatus.failed,
      text: 'Предыдущее успешное описание, ещё актуально для показа.',
    );
    await tester.pumpWidget(wrap(const ProfileSummaryCard(summary: summary, loading: false)));
    await tester.pump();

    expect(find.text('Предыдущее успешное описание, ещё актуально для показа.'),
        findsOneWidget);
    // Нет иконки ошибки/предупреждения поверх текста.
    expect(find.byIcon(Icons.error_outline), findsNothing);
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('status=failed без text (первой генерации не было) — тот же placeholder, что pending',
      (tester) async {
    const summary = ProfileSummary(
      completionPercent: 5,
      status: ProfileSummaryStatus.failed,
      text: null,
    );
    await tester.pumpWidget(wrap(const ProfileSummaryCard(summary: summary, loading: false)));
    await tester.pump();

    expect(find.text('AURA ещё формирует описание — загляните чуть позже.'), findsOneWidget);
  });
}
