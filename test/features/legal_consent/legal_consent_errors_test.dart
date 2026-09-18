import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/features/legal_consent/legal_consent_errors.dart';

/// ⚠ Импорт пакета предполагает имя пакета `vb_mobile` (см.
/// AURA_mobile.md: bundle id `ru.vibebit.vb_mobile`, репозиторий
/// VB-android) — не видел pubspec.yaml, проверь `name:` в нём и поправь
/// импорты во всех тестовых файлах, если реальное имя пакета другое.
void main() {
  DioException dioError({required int status, Object? data}) {
    final requestOptions = RequestOptions(path: '/app/auth/register');
    return DioException(
      requestOptions: requestOptions,
      response: Response(
        requestOptions: requestOptions,
        statusCode: status,
        data: data,
      ),
      type: DioExceptionType.badResponse,
    );
  }

  group('LegalConsentErrors.extractBlockedReason', () {
    test('извлекает blocked_reason из тела ошибки', () {
      final e = dioError(status: 403, data: {'blocked_reason': 'underage'});
      expect(LegalConsentErrors.extractBlockedReason(e), 'underage');
    });

    test('извлекает blocked_reason из FastAPI-обёртки {"detail": {...}} '
        '(живой прогон 2026-09-07 — реальная форма ответа backend)', () {
      final e = dioError(status: 403, data: {'detail': {'blocked_reason': 'underage'}});
      expect(LegalConsentErrors.extractBlockedReason(e), 'underage');
    });

    test('приоритет — прямая форма, если присутствуют обе', () {
      final e = dioError(status: 403, data: {
        'blocked_reason': 'underage',
        'detail': {'blocked_reason': 'declined'},
      });
      expect(LegalConsentErrors.extractBlockedReason(e), 'underage');
    });

    test('detail — строка (обычный FastAPI-текст ошибки, не наш кейс) — null', () {
      final e = dioError(status: 500, data: {'detail': 'Internal Server Error'});
      expect(LegalConsentErrors.extractBlockedReason(e), isNull);
    });

    test('возвращает null, если blocked_reason отсутствует', () {
      final e = dioError(status: 500, data: {'detail': 'server error'});
      expect(LegalConsentErrors.extractBlockedReason(e), isNull);
    });

    test('возвращает null для не-DioException', () {
      expect(LegalConsentErrors.extractBlockedReason(Exception('boom')), isNull);
    });

    test('возвращает null, если data не Map (например, строка)', () {
      final e = dioError(status: 403, data: 'plain text body');
      expect(LegalConsentErrors.extractBlockedReason(e), isNull);
    });
  });

  group('LegalConsentErrors.isUnderage', () {
    test('true на 403 + blocked_reason=underage', () {
      final e = dioError(status: 403, data: {'blocked_reason': 'underage'});
      expect(LegalConsentErrors.isUnderage(e), isTrue);
    });

    test('true на 403 + FastAPI-обёртка detail.blocked_reason=underage', () {
      final e = dioError(status: 403, data: {'detail': {'blocked_reason': 'underage'}});
      expect(LegalConsentErrors.isUnderage(e), isTrue);
    });

    test('false на 403 с другим blocked_reason', () {
      final e = dioError(status: 403, data: {'blocked_reason': 'declined'});
      expect(LegalConsentErrors.isUnderage(e), isFalse);
    });

    test('false на 400 + blocked_reason=underage (неверный статус)', () {
      final e = dioError(status: 400, data: {'blocked_reason': 'underage'});
      expect(LegalConsentErrors.isUnderage(e), isFalse);
    });

    test('false для generic сетевой ошибки без response', () {
      final e = DioException(
        requestOptions: RequestOptions(path: '/app/auth/register'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(LegalConsentErrors.isUnderage(e), isFalse);
    });
  });

  group('LegalConsentErrors.isConsentRequired', () {
    test('true на 400 + blocked_reason=consent_required', () {
      final e = dioError(status: 400, data: {'blocked_reason': 'consent_required'});
      expect(LegalConsentErrors.isConsentRequired(e), isTrue);
    });

    test('false на 403 + blocked_reason=consent_required (неверный статус)', () {
      final e = dioError(status: 403, data: {'blocked_reason': 'consent_required'});
      expect(LegalConsentErrors.isConsentRequired(e), isFalse);
    });

    test('false на 400 без blocked_reason вообще', () {
      final e = dioError(status: 400, data: {'detail': 'bad request'});
      expect(LegalConsentErrors.isConsentRequired(e), isFalse);
    });
  });
}
