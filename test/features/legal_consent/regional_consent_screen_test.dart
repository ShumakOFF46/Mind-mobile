import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vb_mobile/core/api/api_client.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/legal_consent_gate_cache.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/legal_consent/regional_consent_screen.dart';
import '../../helpers/fake_http_client_adapter.dart';

/// ✅ `AppTheme.light` — геттер, подтверждено живым прогоном 2026-09-06
/// (см. legal_consent_gate_block_test.dart). Ссылки на документы (`_openDocument` → `LegalDocumentLauncher.open()`)
/// здесь НЕ мокаются и НЕ тестируются намеренно — `launchUrl()` дёргает
/// платформенный канал, что выходит за рамки виджет-теста; кнопки-ссылки
/// проверяются только на факт наличия в дереве (см. последний тест).
class _MarkerScreen extends StatelessWidget {
  final String label;
  const _MarkerScreen(this.label);
  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

Widget _harness({String? detectedRegion, Map<String, String>? regionLabel}) {
  final router = GoRouter(
    initialLocation: '/regional',
    routes: [
      GoRoute(
        path: '/regional',
        builder: (context, state) => RegionalConsentScreen(
          detectedRegion: detectedRegion,
          regionLabel: regionLabel,
        ),
      ),
      GoRoute(path: '/chat', builder: (context, state) => const _MarkerScreen('CHAT_REACHED')),
    ],
  );

  return MaterialApp.router(
    theme: AppTheme.light,
    routerConfig: router,
    locale: const Locale('ru'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
  );
}

void main() {
  setUp(() {
    LegalConsentGateCache.reset();
  });

  testWidgets('detectedRegion передан конструктором — GET /status НЕ вызывается', (tester) async {
    var statusCalled = false;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      statusCalled = true;
      return const FakeResponse(statusCode: 200, data: {'regional_passed': false});
    });

    await tester.pumpWidget(_harness(
      detectedRegion: 'EU',
      regionLabel: const {'ru': 'Евросоюз', 'en': 'European Union'},
    ));
    await tester.pumpAndSettle();

    expect(statusCalled, isFalse);
    expect(find.textContaining('Евросоюз', findRichText: true), findsOneWidget);
  });

  testWidgets('detectedRegion=null — экран сам вызывает GET /status', (tester) async {
    var statusCalled = false;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      statusCalled = true;
      expect(options.path, contains('/app/legal-consent/status'));
      return const FakeResponse(
        statusCode: 200,
        data: {
          'regional_passed': false,
          'detected_region': 'RU',
          'region_label': {'ru': 'Россия', 'en': 'Russia'},
        },
      );
    });

    await tester.pumpWidget(_harness());
    await tester.pumpAndSettle();

    expect(statusCalled, isTrue);
    expect(find.textContaining('Россия', findRichText: true), findsOneWidget);
  });

  testWidgets('переключатель "не мой регион" показывает RegionSelector', (tester) async {
    await tester.pumpWidget(_harness(detectedRegion: 'EU', regionLabel: const {'ru': 'Евросоюз'}));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(find.byType(ChoiceChip), findsNWidgets(6)); // EU/US/LATAM/RU/CN/OTHER
  });

  testWidgets('submit без выбора региона (regionConfirm=false, manualRegion=null) — no-op',
      (tester) async {
    var submitCalled = false;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      if (options.path.contains('/legal-consent/regional')) submitCalled = true;
      return const FakeResponse(statusCode: 200, data: {'passed': true});
    });

    await tester.pumpWidget(_harness(detectedRegion: 'EU', regionLabel: const {'ru': 'Евросоюз'}));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch)); // "не мой регион", ничего не выбрано
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(submitCalled, isFalse);
  });

  testWidgets('успешный submit (passed=true) → /chat + markRegionalPassed()', (tester) async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      if (options.path.contains('/legal-consent/regional')) {
        expect(options.data['region_confirm'], isTrue);
        expect(options.data['chat_tos_accepted'], isTrue);
        expect(options.data['personal_data_accepted'], isTrue);
        return const FakeResponse(statusCode: 200, data: {'passed': true});
      }
      throw StateError('unexpected path: ${options.path}');
    });

    await tester.pumpWidget(_harness(detectedRegion: 'EU', regionLabel: const {'ru': 'Евросоюз'}));
    await tester.pumpAndSettle();

    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(0));
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('CHAT_REACHED'), findsOneWidget);
    expect(LegalConsentGateCache.debugCachedValue, isTrue);
  });

  testWidgets('declined → DeclinedConsentView, кнопка "назад" восстанавливает форму без сброса чекбоксов',
      (tester) async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      return const FakeResponse(
        statusCode: 200,
        data: {'passed': false, 'blocked_reason': 'declined'},
      );
    });

    await tester.pumpWidget(_harness(detectedRegion: 'EU', regionLabel: const {'ru': 'Евросоюз'}));
    await tester.pumpAndSettle();

    final checkboxes = find.byType(Checkbox);
    await tester.tap(checkboxes.at(0));
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('Без согласия с условиями продолжить нельзя'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing); // форма скрыта под DeclinedConsentView

    await tester.tap(find.text('Вернуться к условиям'));
    await tester.pumpAndSettle();

    // Форма вернулась, чекбоксы НЕ сброшены (значения сохранены в State).
    final restoredCheckboxes =
        tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
    expect(restoredCheckboxes, hasLength(2));
    expect(restoredCheckboxes.every((c) => c.value == true), isTrue);
  });

  testWidgets('ссылки на документы (chat_tos/personal_data) присутствуют в дереве', (tester) async {
    await tester.pumpWidget(_harness(detectedRegion: 'EU', regionLabel: const {'ru': 'Евросоюз'}));
    await tester.pumpAndSettle();

    expect(find.textContaining('условиями использования чата', findRichText: true), findsOneWidget);
    expect(
      find.textContaining('политикой обработки персональных данных', findRichText: true),
      findsOneWidget,
    );
  });
}
