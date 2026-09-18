/// Модели ответов Legal Consent Gate v4
/// (CONTRACT_legal_consent_gate_v4.md, §2/§3/§4/§5).
class RegisterResult {
  final String? detectedRegion;
  final Map<String, String>? regionLabel;

  const RegisterResult({this.detectedRegion, this.regionLabel});

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    final rawLabel = json['region_label'];
    return RegisterResult(
      detectedRegion: json['detected_region'] as String?,
      regionLabel: rawLabel is Map
          ? rawLabel.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }
}

/// Общая форма ответа `/legal-consent/regional` и `/legal-consent/medical`
/// (контракт §3, §4) — идентична для обоих эндпоинтов.
class LegalConsentResult {
  final bool passed;
  final String? blockedReason; // 'declined' | null

  const LegalConsentResult({required this.passed, this.blockedReason});

  factory LegalConsentResult.fromJson(Map<String, dynamic> json) =>
      LegalConsentResult(
        passed: json['passed'] as bool? ?? false,
        blockedReason: json['blocked_reason'] as String?,
      );
}

class LegalConsentStatus {
  final bool regionalPassed;
  final bool medicalPassed;
  final String? detectedRegion;
  final Map<String, String>? regionLabel;

  const LegalConsentStatus({
    required this.regionalPassed,
    required this.medicalPassed,
    this.detectedRegion,
    this.regionLabel,
  });

  factory LegalConsentStatus.fromJson(Map<String, dynamic> json) {
    final rawLabel = json['region_label'];
    return LegalConsentStatus(
      regionalPassed: json['regional_passed'] as bool? ?? false,
      medicalPassed: json['medical_passed'] as bool? ?? false,
      detectedRegion: json['detected_region'] as String?,
      regionLabel: rawLabel is Map
          ? rawLabel.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }
}
