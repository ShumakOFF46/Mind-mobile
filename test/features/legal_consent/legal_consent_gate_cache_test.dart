import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/core/api/api_client.dart';
import 'package:vb_mobile/core/legal_consent_gate_cache.dart';
import '../../helpers/fake_http_client_adapter.dart';

/// ⚠ `LegalConsentGateCache.debugCachedValue` — доступен только внутри
/// пакета через @visibleForTesting; т.к. тестовый файл лежит в отдельном
/// `test/`-дереве (не в `lib/`), аннотация не блокирует компиляцию, но
/// линтер может предупреждать при импорте из другого пакета/lib-файла —
/// это ожидаемо и допустимо для теста.
void main() {
  setUp(() {
    // Сброс кэша перед каждым тестом — иначе порядок тестов внутри файла
    // влияет на результат (кэш статический, живёт между тестами одного
    // процесса).
    LegalConsentGateCache.reset();
  });

  test('ensureRegionalPassed() возвращает true и кэширует при passed=true', () async {
    var callCount = 0;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      return const FakeResponse(
        statusCode: 200,
        data: {'regional_passed': true, 'medical_passed': false},
      );
    });

    final first = await LegalConsentGateCache.ensureRegionalPassed();
    final second = await LegalConsentGateCache.ensureRegionalPassed();

    expect(first, isTrue);
    expect(second, isTrue);
    // Второй вызов НЕ должен снова бить в сеть — кэш-хит (BRIEF §3: "не
    // на каждую навигацию").
    expect(callCount, 1);
  });

  test('ensureRegionalPassed() возвращает false и НЕ кэширует при passed=false', () async {
    var callCount = 0;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      return const FakeResponse(
        statusCode: 200,
        data: {'regional_passed': false, 'medical_passed': false},
      );
    });

    final first = await LegalConsentGateCache.ensureRegionalPassed();
    final second = await LegalConsentGateCache.ensureRegionalPassed();

    expect(first, isFalse);
    expect(second, isFalse);
    // false НЕ кэшируется — каждый заход должен перепроверить (иначе
    // пользователь навсегда застрянет на экране 2 даже после прохождения
    // гейта где-то параллельно).
    expect(callCount, 2);
  });

  test('ensureRegionalPassed() — fail-open (true) при сетевой ошибке', () async {
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      return const FakeResponse(statusCode: 500, data: {'detail': 'server error'});
    });

    final result = await LegalConsentGateCache.ensureRegionalPassed();

    // ⚠ Сознательное решение (не подтверждено оркестратором явно, см.
    // отчёт по брифу) — backend дублирует гейт server-side
    // (CONTRACT_legal_consent_gate_v4.md §7, defense-in-depth).
    expect(result, isTrue);
  });

  test('markRegionalPassed() форсирует кэш в true без сетевого вызова', () async {
    var called = false;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      called = true;
      return const FakeResponse(statusCode: 200, data: {'regional_passed': false});
    });

    LegalConsentGateCache.markRegionalPassed();
    final result = await LegalConsentGateCache.ensureRegionalPassed();

    expect(result, isTrue);
    expect(called, isFalse);
  });

  test('reset() очищает кэш — следующий вызов снова бьёт в сеть', () async {
    var callCount = 0;
    ApiClient.instance.httpClientAdapter = FakeHttpClientAdapter((options) {
      callCount++;
      return const FakeResponse(statusCode: 200, data: {'regional_passed': true});
    });

    await LegalConsentGateCache.ensureRegionalPassed();
    expect(callCount, 1);

    LegalConsentGateCache.reset();
    await LegalConsentGateCache.ensureRegionalPassed();
    expect(callCount, 2);
  });
}
