import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_navigation.dart';

/// Foreground-показ уведомлений — FCM не рисует системный баннер сам,
/// пока приложение на переднем плане (см. BRIEF §4).
class LocalNotifications {
  LocalNotifications._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // TODO(l10n): имя канала — статическая строка. На этапе init() (до
  // runApp(), нет BuildContext) нет доступа к AppLocalizations — уточнить
  // с оркестратором, требуется ли релокализация при смене языка в
  // рантайме, или это приемлемое системное исключение (канал виден
  // только в системных настройках Android, не в UI приложения).
  static const String _channelId = 'default_channel';
  static const String _channelName = 'Уведомления AURA';

  static Future<void> init() async {
    if (_initialized) return;
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  static Future<void> showForMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    await _plugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    final data = jsonDecode(payload) as Map<String, dynamic>;
    PushNavigation.handle(data);
  }
}
