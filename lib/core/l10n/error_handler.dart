import 'dart:io';
import 'package:dio/dio.dart';

class AppError {
  final String     message;
  final AppErrorType type;
  const AppError({required this.message, required this.type});
}

enum AppErrorType { network, server, auth, notFound, timeout, unknown }

/// Строки ошибок передаются снаружи (из l10n), чтобы не зависеть от context.
class ErrorMessages {
  final String network;
  final String noConnection;
  final String timeout;
  final String auth;
  final String notFound;
  final String server;
  final String unknown;
  final String generic;

  const ErrorMessages({
    required this.network,
    required this.noConnection,
    required this.timeout,
    required this.auth,
    required this.notFound,
    required this.server,
    required this.unknown,
    required this.generic,
  });
}

class ErrorHandler {
  static AppError handle(dynamic error, ErrorMessages msg) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return AppError(message: msg.network,      type: AppErrorType.network);
          }
          return AppError(message: msg.noConnection,   type: AppErrorType.network);

        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return AppError(message: msg.timeout,        type: AppErrorType.timeout);

        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 401 || status == 403) {
            return AppError(message: msg.auth,         type: AppErrorType.auth);
          }
          if (status == 404) {
            return AppError(message: msg.notFound,     type: AppErrorType.notFound);
          }
          if (status != null && status >= 500) {
            return AppError(message: msg.server,       type: AppErrorType.server);
          }
          return AppError(message: msg.unknown,        type: AppErrorType.unknown);

        default:
          return AppError(message: msg.noConnection,   type: AppErrorType.network);
      }
    }

    if (error is SocketException) {
      return AppError(message: msg.network,            type: AppErrorType.network);
    }

    return AppError(message: msg.generic,              type: AppErrorType.unknown);
  }

  /// Хелпер — строит ErrorMessages из AppLocalizations одной строкой.
  /// Использование: ErrorHandler.fromL10n(context.l10n)
  static ErrorMessages fromL10n(dynamic l10n) => ErrorMessages(
    network:      l10n.errorNetwork      as String,
    noConnection: l10n.errorNoConnection as String,
    timeout:      l10n.errorTimeout      as String,
    auth:         l10n.errorAuth         as String,
    notFound:     l10n.errorNotFound     as String,
    server:       l10n.errorServer       as String,
    unknown:      l10n.errorUnknown      as String,
    generic:      l10n.errorGeneric      as String,
  );
}
