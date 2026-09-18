import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../storage.dart';
import 'local_notifications.dart';
import 'push_navigation.dart';

typedef RegisterTokenFn = Future<void> Function(String fcmToken);

/// Жизненный цикл FCM-токена и обработка входящих пушей
/// (CONTRACT_push_notifications_v1). [registerToken] инжектируется по
/// аналогии с ChatController(streamChat: ...) — тестируемость без
/// реального Dio/Firebase.
class PushService {
  PushService({RegisterTokenFn? registerToken})
      : _registerToken = registerToken ?? ApiClient.registerPushToken;

  final RegisterTokenFn _registerToken;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _listenersAttached = false;

  /// Вызывать один раз при старте приложения, независимо от логина/
  /// разрешения.
  void attachListeners() {
    if (_listenersAttached) return;
    _listenersAttached = true;
    _messaging.onTokenRefresh.listen(_handleTokenRefresh);
    FirebaseMessaging.onMessage.listen(LocalNotifications.showForMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
  }

  /// При каждом старте приложения — НЕ запрашивает разрешение (BRIEF §2:
  /// разрешение просим только после логина), только регистрирует токен,
  /// если разрешение уже дано ранее и юзер залогинен.
  Future<void> registerIfAuthorizedAndLoggedIn() async {
    try {
      final settings = await _messaging.getNotificationSettings();
      if (!_isAuthorized(settings)) return;
      if (!await _hasActiveSession()) return;
      await _registerCurrentToken();
    } catch (e) {
      debugPrint('PushService.registerIfAuthorizedAndLoggedIn failed: $e');
    }
  }

  /// Вызывать сразу после успешного логина/регистрации — показывает
  /// системный диалог разрешения (Android 13+, POST_NOTIFICATIONS).
  Future<void> requestPermissionAndRegister() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (_isAuthorized(settings)) await _registerCurrentToken();
    } catch (e) {
      debugPrint('PushService.requestPermissionAndRegister failed: $e');
    }
  }

  /// Пуш, открывший приложение из terminated-состояния (тапы из
  /// foreground/background идут через onMessageOpenedApp).
  Future<void> handleInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) PushNavigation.handle(message.data);
  }

  bool _isAuthorized(NotificationSettings settings) =>
      settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;

  Future<bool> _hasActiveSession() async {
    final userName = await AppStorage.getUserName();
    final token = await AppStorage.getAccessToken();
    return userName != null && token != null;
  }

  Future<void> _registerCurrentToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _registerToken(token);
  }

  Future<void> _handleTokenRefresh(String token) async {
    try {
      await _registerToken(token);
    } catch (e) {
      debugPrint('PushService.onTokenRefresh registration failed: $e');
    }
  }

  void _handleOpenedMessage(RemoteMessage message) {
    PushNavigation.handle(message.data);
  }
}
