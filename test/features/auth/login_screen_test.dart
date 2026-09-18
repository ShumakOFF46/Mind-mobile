import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vb_mobile/core/api/api_client.dart';
import 'package:vb_mobile/core/l10n/app_localizations.dart';
import 'package:vb_mobile/core/push/push_providers.dart';
import 'package:vb_mobile/core/push/push_service.dart';
import 'package:vb_mobile/core/theme.dart';
import 'package:vb_mobile/features/auth/login_screen.dart';
import 'package:vb_mobile/features/auth/widgets/birth_date_field.dart';
import 'package:vb_mobile/features/legal_consent/regional_consent_screen.dart';
import '../../helpers/fake_http_client_adapter.dart';

/// ⚠⚠⚠ САМЫЙ РИСКОВАННЫЙ файл в этой пачке — три предположения, которые
/// я не мог проверить без реальных core/theme.dart и core/push/
/// push_providers.dart:
///
/// 1. `AppTheme.light` — ✅ геттер (не метод), подтверждено живым
///    прогоном 2026-09-06, см. legal_consent_gate_block_test.dart.
/// 2. `pushServiceProvider` — ✅ подтверждено живым прогоном 2026-09-06:
///    `Provider<PushService>` (core/push/push_service.dart), метод
///    `Future<void> requestPermissionAndRegister()` (не `void` — первая
///    попытка ошиблась именно на этом, компилятор поправил).
///    `_FakePushService` реализует только этот метод (+ `noSuchMethod`
///    fallback на случай других членов интерфейса).
/// 3. Дата рождения выбирается через РЕАЛЬНЫЙ `showDatePicker` —
///    вместо навигации по календарной сетке (хрупко, зависит от
///    текущей даты и раскладки календаря) тест просто подтверждает
///    уже выставленный `initialDate` кнопкой "OK" — тот
///    самый `DateTime(now.year - 25, ...)` дефолт из
///    `BirthDateField._pick()`. Если имя/расположение кнопки
///    подтверждения в вашей версии Flutter отличается — заменить
///    `find.text('OK')` на актуальный selector.
class _FakePushService implements PushService {
  bool requested = false;

  @override
  Future<void> requestPermissionAndRegister() async {
    requested = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MarkerScreen extends StatelessWidget {
  final String label;
  const _MarkerScreen(this.label);
  @override
  Widget build(BuildContext context) => Scaffold(body: Text(label));
}

Widget _harness({
  required _FakePushService fakePush,
  RegionalConsentArgs? Function(RegionalConsentArgs? args)? onRegionalArgs,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/legal-consent/regional',
        builder: (context, state) {
          final args = state.extra as RegionalConsentArgs?;
          onRegionalArgs?.call(args);
          return const _MarkerScreen('REGIONAL_SCREEN_REACHED');
        },
      ),
      GoRoute(
        path: '/legal-consent/underage',
        builder: (context, state) => const _MarkerScreen('UNDERAGE_SCREEN_REACHED'),
      ),
    ],
  );

  return ProviderScope(
    overrides: [pushServiceProvider.overrideWithValue(fakePush)],
    child: MaterialApp.router(
      theme: AppTheme.light,
      routerConfig: router,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

/// Проходит имя → дату рождения (подтверждает дефолт пикера) → чекбокс.
Future<void> _fillValidForm(WidgetTester tester, {String name = 'Alika'}) async {
  await tester.enterText(find.byType(TextField), name);
  // ⚠ ElevatedButton сам построен на InkWell внутри — find.byType(InkWell)
  // без уточнения находит 2 виджета (сам BirthDateField + кнопка).
  // Сужаем поиск через find.descendant.
  await tester.tap(find.descendant(
    of: find.byType(BirthDateField),
    matching: find.byType(InkWell),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('кнопка Continue отключена без даты рождения и согласия', (tester) async {
    await tester.pumpWidget(_harness(fakePush: _FakePushService()));
    await tester.pumpAndSettle();

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('кнопка активна после даты рождения + чекбокса (имя не проверяется disable-логикой)',
      (tester) async {
    await tester.pumpWidget(_harness(fakePush: _FakePushService()));
    await tester.pumpAndSettle();
    await _fillValidForm(tester);

    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNotNull);
  });

  testWidgets('успешная регистрация → переход на /legal-consent/regional с detectedRegion/regionLabel',
      (tester) async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      expect(options.path, contains('/app/auth/register'));
      expect(options.data['birth_date'], isA<String>());
      expect(options.data['basic_data_consent'], isTrue);
      expect(options.data['display_name'], 'Alika');
      return const FakeResponse(
        statusCode: 200,
        data: {
          'access_token': 'atk',
          'refresh_token': 'rtk',
          'detected_region': 'EU',
          'region_label': {'ru': 'Евросоюз', 'en': 'European Union'},
        },
      );
    });

    RegionalConsentArgs? capturedArgs;
    final fakePush = _FakePushService();
    await tester.pumpWidget(_harness(
      fakePush: fakePush,
      onRegionalArgs: (args) => capturedArgs = args,
    ));
    await tester.pumpAndSettle();

    await _fillValidForm(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('REGIONAL_SCREEN_REACHED'), findsOneWidget);
    expect(capturedArgs?.detectedRegion, 'EU');
    expect(capturedArgs?.regionLabel?['ru'], 'Евросоюз');
    // Push-разрешение запрашивается после успешного логина (fire-and-forget).
    expect(fakePush.requested, isTrue);
  });

  testWidgets('403 blocked_reason=underage → переход на /legal-consent/underage', (tester) async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      return const FakeResponse(statusCode: 403, data: {'blocked_reason': 'underage'});
    });

    await tester.pumpWidget(_harness(fakePush: _FakePushService()));
    await tester.pumpAndSettle();
    await _fillValidForm(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('UNDERAGE_SCREEN_REACHED'), findsOneWidget);
  });

  testWidgets('generic 500 ошибка → SnackBar, форма остаётся на месте (нет навигации)',
      (tester) async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      return const FakeResponse(statusCode: 500, data: {'detail': 'boom'});
    });

    await tester.pumpWidget(_harness(fakePush: _FakePushService()));
    await tester.pumpAndSettle();
    await _fillValidForm(tester);
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(find.text('REGIONAL_SCREEN_REACHED'), findsNothing);
    expect(find.text('UNDERAGE_SCREEN_REACHED'), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
