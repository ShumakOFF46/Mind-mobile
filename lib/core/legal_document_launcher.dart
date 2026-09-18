import 'package:url_launcher/url_launcher.dart';
import 'api/legal_consent_api_client.dart';

/// Общий хелпер открытия полного текста юридического документа
/// (CONTRACT_legal_consent_gate_v4.md §8). Переиспользуется экраном
/// регионального согласия, экраном регистрации (basic_data_consent) и
/// SDUI-блоком legal_consent_gate — не дублирует try/catch+launchUrl в
/// трёх местах.
///
/// ⚠ Предполагает, что `url_launcher` уже добавлен в pubspec.yaml — не
/// проверено (файл pubspec.yaml не входил в переданные материалы).
class LegalDocumentLauncher {
  const LegalDocumentLauncher._();

  static Future<bool> open(String documentType, {String? region}) async {
    try {
      final doc = await LegalConsentApiClient.getLegalDocument(
        documentType,
        region: region,
      );
      final url = doc['url'] as String?;
      if (url == null) return false;
      return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
