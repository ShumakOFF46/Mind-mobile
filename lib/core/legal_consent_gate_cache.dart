import 'package:flutter/foundation.dart';
import 'api/legal_consent_api_client.dart';

/// Кэш результата регионального гейта (CONTRACT_legal_consent_gate_v4.md
/// §5) на время жизни процесса приложения — НЕ персистится в
/// SharedPreferences. "При каждом запуске приложения" (BRIEF §3)
/// реализовано естественно: кэш обнуляется вместе с процессом при
/// перезапуске, повторный GET /status вызывается заново. В рамках ОДНОЙ
/// сессии — проверяется один раз (не на каждую go_router-навигацию),
/// результат кэшируется до logout/новой сессии.
class LegalConsentGateCache {
  const LegalConsentGateCache._();

  static bool? _regionalPassed;

  @visibleForTesting
  static bool? get debugCachedValue => _regionalPassed;

  /// Сетевая ошибка при проверке НЕ блокирует навигацию (fail-open) —
  /// backend дублирует гейт как defense-in-depth (контракт §7,
  /// `check_regional()` внутри `run_agentic_chat()`). НЕ подтверждено
  /// оркестратором как согласованное поведение при недоступности сети —
  /// открытый вопрос, см. отчёт.
  static Future<bool> ensureRegionalPassed() async {
    if (_regionalPassed == true) return true;
    try {
      final status = await LegalConsentApiClient.getStatus();
      _regionalPassed = status.regionalPassed;
      return status.regionalPassed;
    } catch (_) {
      return true;
    }
  }

  static void markRegionalPassed() => _regionalPassed = true;

  /// Обязателен на logout (см. storage.dart::clearUser()) — иначе
  /// следующий пользователь на том же устройстве в рамках того же
  /// процесса унаследует чужой пройденный гейт.
  static void reset() => _regionalPassed = null;
}
