import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Минимальный фейковый HttpClientAdapter для тестов ApiClient/
/// LegalConsentApiClient — БЕЗ mockito/mocktail (проект использует
/// injection-швы вместо мок-библиотек, см. AURA_mobile.md
/// "Testing: flutter_test only... injection seams used instead").
///
/// Подменяется через `ApiClient.instance.httpClientAdapter = ...` —
/// `ApiClient.instance` уже публично экспонирует общий Dio-синглтон
/// именно для этой цели (см. core/api/api_client.dart).
///
/// Dio сам решает, бросать ли DioException(badResponse), исходя из
/// statusCode (validateStatus по умолчанию принимает только 200-299) —
/// адаптеру НЕ нужно самому кидать исключение на 403/400, достаточно
/// вернуть реальный statusCode, остальное сделает сам Dio pipeline.
class FakeHttpClientAdapter implements HttpClientAdapter {
  final FakeResponse Function(RequestOptions options) responder;

  FakeHttpClientAdapter(this.responder);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final res = responder(options);
    return ResponseBody.fromString(
      jsonEncode(res.data),
      res.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class FakeResponse {
  final int statusCode;
  final Map<String, dynamic> data;
  const FakeResponse({required this.statusCode, required this.data});
}
