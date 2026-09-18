import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart'; // ValueNotifier
import 'legal_consent_gate_cache.dart';

class AppStorage {
  static const _keyUserId         = 'app_user_id';
  static const _keyUserName       = 'user_name';
  static const _keyAccessToken    = 'access_token';
  static const _keyRefreshToken   = 'refresh_token';
  static const _keyProjectId      = 'active_project_id';
  static const _keyProjectJson    = 'active_project_json';
  static const _keyConversationId = 'conversation_id';
  static const _keyAvatarPath = 'avatar_path';

  // Реактивный нотифаер — оба экрана подписываются без Riverpod
  static final avatarNotifier = ValueNotifier<String?>(null);

  /// Вызвать один раз при старте (main.dart или initState ProfileScreen)
  static Future<void> initAvatarNotifier() async {
    avatarNotifier.value = await getAvatarPath();
  }

  static Future<void> saveAvatarPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatarPath, path);
    avatarNotifier.value = path;
  }

  static Future<String?> getAvatarPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAvatarPath);
  }


  static Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_keyUserId);
    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(_keyUserId, id);
    }
    return id;
  }

  static Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserName, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
  }

  static Future<void> saveConversationId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyConversationId, id);
  }

  static Future<String?> getConversationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyConversationId);
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyProjectId);
    await prefs.remove(_keyProjectJson);
    await prefs.remove(_keyConversationId);
    await prefs.remove(_keyAvatarPath);
    avatarNotifier.value = null;
    LegalConsentGateCache.reset(); // v4: сброс кэша регионального гейта
  }
}
