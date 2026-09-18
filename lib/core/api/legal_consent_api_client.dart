import 'package:dio/dio.dart';
import 'api_client.dart';
import 'models/legal_consent_models.dart';
import '../storage.dart';

/// Legal Consent Gate v4 (CONTRACT_legal_consent_gate_v4.md, §2-5, §8).
///
/// Вынесено ИЗ api_client.dart отдельным файлом по правилу "не более
/// 300-400 строк на файл" (api_client.dart уже был на границе — 301
/// строка до этого брифа). Работает ЧЕРЕЗ публичный `ApiClient.instance`
/// (общий singleton Dio с уже настроенными token-интерсепторами) — не
/// заводит параллельный HTTP-клиент, поэтому не нарушает правило "все
/// сетевые вызовы — только через api_client.dart" по существу, только
/// по организации файлов.
class LegalConsentApiClient {
  const LegalConsentApiClient._();

  static Dio get _dio => ApiClient.instance;

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// `POST /api/app/auth/register` (контракт §2). В ОТЛИЧИЕ от старого
  /// приватного `ApiClient._register()` — ошибки НЕ глотаются. 403
  /// (`blocked_reason: "underage"`) и 400 (`"consent_required"`) должны
  /// дойти до вызывающего экрана как DioException (см.
  /// LegalConsentErrors.extractBlockedReason).
  static Future<RegisterResult> register({
    required String appUserId,
    required DateTime birthDate,
    required bool basicDataConsent,
    String? displayName,
    String platform = 'android',
  }) async {
    final body = <String, dynamic>{
      'app_user_id': appUserId,
      'platform': platform,
      'birth_date': _isoDate(birthDate),
      'basic_data_consent': basicDataConsent,
    };
    if (displayName != null) body['display_name'] = displayName;

    final response = await _dio.post('/app/auth/register', data: body);
    await AppStorage.saveTokens(
      accessToken: response.data['access_token'] as String,
      refreshToken: response.data['refresh_token'] as String,
    );
    return RegisterResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// `POST /api/app/legal-consent/regional` (контракт §3).
  static Future<LegalConsentResult> submitRegionalConsent({
    required bool regionConfirm,
    String? region,
    required bool chatTosAccepted,
    required bool personalDataAccepted,
  }) async {
    final body = <String, dynamic>{
      'region_confirm': regionConfirm,
      'chat_tos_accepted': chatTosAccepted,
      'personal_data_accepted': personalDataAccepted,
    };
    if (!regionConfirm) body['region'] = region;

    final response = await _dio.post('/app/legal-consent/regional', data: body);
    return LegalConsentResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// `POST /api/app/legal-consent/medical` (контракт §4) — one-shot, оба
  /// поля сразу, без партиал-механики.
  static Future<LegalConsentResult> submitMedicalConsent({
    required bool medicalDataAccepted,
    required bool modelTrainingAccepted,
  }) async {
    final response = await _dio.post('/app/legal-consent/medical', data: {
      'medical_data_accepted': medicalDataAccepted,
      'model_training_accepted': modelTrainingAccepted,
    });
    return LegalConsentResult.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// `GET /api/app/legal-consent/status` (контракт §5) — app-launch
  /// проверка (см. LegalConsentGateCache).
  static Future<LegalConsentStatus> getStatus() async {
    final response = await _dio.get('/app/legal-consent/status');
    return LegalConsentStatus.fromJson(Map<String, dynamic>.from(response.data));
  }

  /// `GET /api/legal-documents/{document_type}?region=` (контракт §8) —
  /// публичный, БЕЗ JWT. `skipAuth` — см. ApiClient.init() (интерсептор
  /// пропускает Authorization при этом флаге).
  static Future<Map<String, dynamic>> getLegalDocument(
    String documentType, {
    String? region,
  }) async {
    final response = await _dio.get(
      '/legal-documents/$documentType',
      queryParameters: region != null ? {'region': region} : null,
      options: Options(extra: {'skipAuth': true}),
    );
    return Map<String, dynamic>.from(response.data);
  }
}
