import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../constants.dart';
import '../storage.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl:        AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 60),
      headers:        {'Content-Type': 'application/json'},
    ),
  );

  static Dio get instance => _dio;

  static Future<void> init() async {
    // v4 (CONTRACT_legal_consent_gate_v4.md §2): регистрация больше НЕ
    // вызывается неявно при каждом старте приложения — это теперь гейт с
    // синхронной проверкой возраста/базового согласия, привязанный к
    // конкретному экрану (features/auth/login_screen.dart), а не побочный
    // эффект старта. Если токен уже есть — пользователь уже прошёл
    // регистрацию в прошлой сессии, ничего не делаем. Если токена нет —
    // ждём явного LegalConsentApiClient.register() из LoginScreen;
    // router.dart до этого держит пользователя на /login.
    //
    // ⚠ Изменение поведения относительно pre-v4: раньше здесь стоял
    // слепой `_register(appUserId, displayName: userName)` для АНОНИМНОЙ
    // предрегистрации ДО ввода имени — это несовместимо с синхронной
    // валидацией возраста (аккаунт не должен создаваться до подтверждения
    // 18+). `_register()`/`updateDisplayName()` ниже оставлены
    // нетронутыми на случай других вызывающих мест вне этого брифа (не
    // проверено — main.dart/profile_screen.dart не входили в переданные
    // файлы) — см. отчёт: если `_register()` где-то ещё вызывается для
    // СУЩЕСТВУЮЩЕГО пользователя, backend v4 по буквальному тексту
    // контракта §2 ожидает birth_date/basic_data_consent в body КАЖДОГО
    // register() — открытый вопрос к бэкенду, не решаю его здесь
    // односторонне.

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // v4 §8: GET /api/legal-documents/{type} — публичный, без JWT.
          // Помечается вызывающим кодом через extra['skipAuth'] (см.
          // LegalConsentApiClient.getLegalDocument()).
          if (options.extra['skipAuth'] == true) {
            return handler.next(options);
          }
          final token = await AppStorage.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final token = await AppStorage.getAccessToken();
              error.requestOptions.headers['Authorization'] = 'Bearer $token';
              final response = await _dio.fetch(error.requestOptions);
              return handler.resolve(response);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // ─── Auth ─────────────────────────────────────────────

  static Future<void> _register({
    required String appUserId,
    String? displayName,
    String platform = 'android',
  }) async {
    try {
      final body = <String, dynamic>{
        'app_user_id': appUserId,
        'platform':    platform,
      };
      if (displayName != null) body['display_name'] = displayName;

      final response = await _dio.post('/app/auth/register', data: body);
      await AppStorage.saveTokens(
        accessToken:  response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
    } catch (e) {
      // Продолжаем без токена
    }
  }

  static Future<void> updateDisplayName(String displayName) async {
    final userId = await AppStorage.getOrCreateUserId();
    await _register(appUserId: userId, displayName: displayName);
  }

  static Future<bool> _tryRefresh() async {
    final refreshToken = await AppStorage.getRefreshToken();
    if (refreshToken == null) return false;
    try {
      final response = await _dio.post(
        '/app/auth/refresh',
        data: {'refresh_token': refreshToken},
      );
      await AppStorage.saveTokens(
        accessToken:  response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─── Push (CONTRACT_push_notifications_v1 §5) ─────────

  /// Регистрирует/обновляет FCM-токен устройства на бэкенде. Вызывается
  /// при старте приложения (если разрешение уже дано) и в
  /// FirebaseMessaging.onTokenRefresh (см. core/push/push_service.dart).
  static Future<void> registerPushToken(String fcmToken) async {
    await _dio.post('/app/push/register-token', data: {
      'fcm_token': fcmToken,
      'platform':  'android',
    });
  }

  // ─── Chat ─────────────────────────────────────────────

  static Stream<Map<String, dynamic>> streamChat({
    required String prompt,
    String?         conversationId,
    List<Map<String, dynamic>>? busySlots,
  }) async* {
    final body = <String, dynamic>{
      'prompt': prompt,
      'stream': true,
    };
    if (conversationId != null) body['conversation_id'] = conversationId;
    if (busySlots != null)      body['busy_slots']      = busySlots;

    final response = await _dio.post<ResponseBody>(
      '/app/chat',
      data:    body,
      options: Options(responseType: ResponseType.stream),
    );

    final stream = response.data!.stream;
    String buffer = '';

    await for (final bytes in stream) {
      buffer += utf8.decode(bytes);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (!line.startsWith('data:')) continue;
        final raw = line.substring(5).trim();
        if (raw == '[DONE]') return;
        if (raw.isEmpty) continue;
        try {
          yield jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {}
      }
    }
  }

  // ─── History ──────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> loadHistory(
    String conversationId,
  ) async {
    final response = await _dio.get('/app/messages/$conversationId');
    return List<Map<String, dynamic>>.from(response.data);
  }

  // ─── Calendar ─────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getCalendarEvents({
    String? category,
    bool    activeOnly = true,
  }) async {
    final params = <String, dynamic>{'active_only': activeOnly};
    if (category != null) params['category'] = category;

    final response = await _dio.get(
      '/app/calendar/events',
      queryParameters: params,
    );
    return List<Map<String, dynamic>>.from(response.data);
  }

  static Future<void> updateCalendarEvent({
    required String               eventId,
    Map<String, dynamic>?         recurrence,
    String?                       title,
    String?                       notes,
    int?                          durationMinutes,
    bool?                         isActive,
  }) async {
    final data = <String, dynamic>{};
    if (recurrence      != null) data['recurrence']       = recurrence;
    if (title           != null) data['title']            = title;
    if (notes           != null) data['notes']            = notes;
    if (durationMinutes != null) data['duration_minutes'] = durationMinutes;
    if (isActive        != null) data['is_active']        = isActive;
    await _dio.patch('/app/calendar/events/$eventId', data: data);
  }

  static Future<void> deleteCalendarEvent(String eventId) async {
    await _dio.delete('/app/calendar/events/$eventId');
  }

  static Future<void> syncCalendarEvents({
    required List<Map<String, dynamic>> records,
  }) async {
    await _dio.post('/app/calendar/sync', data: {'records': records});
  }

  /// Флоу 4 (CONTRACT_flow4_scheduling_v1.md §3) — приём предложенного
  /// слота негоциации. Структурированный HTTP-вызов, СОЗНАТЕЛЬНО не
  /// идёт через streamChat()/SSE и не проходит через LLM — выбор уже
  /// структурирован тапом по кандидату (universal_dialog_engine.md §9).
  ///
  /// Ответ — обычный JSON, НЕ SSE:
  /// {"status": "confirmed", "event_id": "(uuid события)"}
  /// или {"status": "error", "reason": "stale_round"|"not_found"|"not_owner"}
  /// ✅ ПОДТВЕРЖДЕНО ЖИВЫМ КОДОМ backend (REPORT_backend_flow4_mobile_
  /// verification_response.md, 2026-09-03, цитата routers/app_calendar.py):
  /// обе ветки — HTTP 200, ни `raise HTTPException` на доменных случаях
  /// нет вообще, каждая — простой `return {...}`. Это значит `dio` НИКОГДА
  /// не бросит `DioException` на доменной ошибке этого эндпоинта — она
  /// всегда попадёт в `try`, не в `catch`, вызывающий код (ChatController)
  /// обязан проверять поле `status`, а не полагаться на try/catch для
  /// доменной логики.
  /// ⚠ Исключение — 401 (истёкший/невалидный токен, `get_current_app_user`
  /// Depends) — ЭТО настоящий не-2xx с ДРУГОЙ формой тела (`{"detail":
  /// "..."}"`, не `{"status","reason"}`), общий для всего API паттерн, не
  /// специфика этого эндпоинта. Уже корректно обрабатывается существующим
  /// `catch`/`ErrorHandler.handle()` (badResponse status 401/403 → auth-
  /// сообщение) — проверено по факту ответа backend, доп. правка кода не
  /// потребовалась.
  static Future<Map<String, dynamic>> acceptSchedulingSlot({
    required String schedulingSessionId,
    required String slotId,
  }) async {
    final response = await _dio.post(
      '/app/calendar/scheduling-sessions/$schedulingSessionId/accept',
      data: {'slot_id': slotId},
    );
    return Map<String, dynamic>.from(response.data);
  }

  // ─── Photos ───────────────────────────────────────────

  /// Загрузить одно фото на бэкенд
  static Future<Map<String, dynamic>> uploadPhoto({
    required Uint8List fileBytes,
    String             mimeType = 'image/jpeg',
    Map<String, dynamic>? qualityMetadata,
  }) async {
    final ext      = mimeType.split('/').last;
    final filename = 'photo_${DateTime.now().millisecondsSinceEpoch}.$ext';

    final formDataMap = <String, dynamic>{
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename:    filename,
        contentType: DioMediaType.parse(mimeType),
      ),
    };

    // Добавляем quality_metadata как JSON строку (если есть)
    if (qualityMetadata != null) {
      formDataMap['quality_metadata'] = jsonEncode(qualityMetadata);
    }

    final formData = FormData.fromMap(formDataMap);

    final response = await _dio.post(
      '/app/photos',
      data:    formData,
      options: Options(
        headers:         {'Content-Type': 'multipart/form-data'},
        receiveTimeout:  const Duration(seconds: 120),
      ),
    );
    return Map<String, dynamic>.from(response.data);
  }

  /// Получить список фото пользователя
  static Future<List<Map<String, dynamic>>> getPhotos() async {
    final response = await _dio.get('/app/photos');
    final data     = response.data as Map<String, dynamic>;
    return List<Map<String, dynamic>>.from(data['photos'] ?? []);
  }

  /// Удалить фото
  static Future<void> deletePhoto(String photoId) async {
    await _dio.delete('/app/photos/$photoId');
  }

  // ─── Beauty Profile ───────────────────────────────────

  /// Получить beauty-профиль пользователя
  static Future<Map<String, dynamic>> getBeautyProfile() async {
    final response = await _dio.get('/app/profile');
    return Map<String, dynamic>.from(response.data);
  }

  /// CONTRACT_profile_summary_v1.md §4 — completion_percent (синхронный
  /// агрегат) + summary.{status,text,generated_at} (LLM, асинхронный,
  /// закэшированный). Обычный GET, НЕ streamChat()/SSE — read-путь, не
  /// chat. Нет отдельного PUT/POST на ручную регенерацию в v1.
  static Future<Map<String, dynamic>> getProfileSummary() async {
    final response = await _dio.get('/app/profile-summary');
    return Map<String, dynamic>.from(response.data);
  }
}
