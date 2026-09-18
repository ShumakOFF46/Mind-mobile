# AURA Mobile — Beauty AI Consultant

> **Flutter 3.x / Dart 3.x** — мультиплатформенное приложение (Android, iOS, Web, Desktop).
> **State management:** `flutter_riverpod` (ProviderScope) + `ChangeNotifier` для контроллеров.
> **Navigation:** `go_router` (декларативные маршруты + редиректы).
> **Networking:** `dio` (SSE streaming + multipart upload + interceptors).
> **Local storage:** `shared_preferences` (токены, user_id, conversation_id, avatar).
> **L10n:** `flutter_localizations` + ручные ARB-подобные классы (ru/en/kk).
> **ML/Computer Vision:** `camera` + `google_mlkit_face_detection` (офлайн) + `image` (пиксельный анализ).
> **Speech:** `speech_to_text` (on-device STT, ru_RU).
> **Calendar:** `device_calendar` (планируемая интеграция с системным календарём).

---

## 1. Дерево файлов (lib/)

```
lib/
├── main.dart                     # Точка входа, ProviderScope, Theme, Localizations, Router
├── router.dart                   # GoRouter: /login → /chat, /calendar, /profile + кастомные переходы
├── core/
│   ├── constants.dart            # AppConstants.baseUrl = 'https://vibe-bit.ru/api'
│   ├── theme.dart                # AuraColors, AuraColorScheme, AppTheme (light/dark, Material3)
│   ├── storage.dart              # AppStorage: SharedPreferences wrapper + ValueNotifier avatar
│   ├── l10n/
│   │   ├── app_localizations.dart    # Абстрактный класс + delegate + supportedLocales [en,ru,kk]
│   │   ├── l10n_en.dart              # Английские строки
│   │   ├── l10n_ru.dart              # Русские строки (основной язык)
│   │   └── l10n_kk.dart              # Казахские строки
│   └── api/
│       ├── api_client.dart       # Dio singleton + interceptors (auth, refresh) + все HTTP методы
│       └── error_handler.dart    # AppError/ErrorMessages + маппинг DioException → локализованные строки
├── features/
│   ├── auth/
│   │   └── login_screen.dart     # ConsumerStatefulWidget: ввод имени → AppStorage + ApiClient.updateDisplayName
│   ├── chat/
│   │   ├── chat_controller.dart  # ChangeNotifier: SSE поток, история, фото, календарь, speech, сообщения
│   │   ├── chat_provider.dart    # (пустой, зарезервирован под Riverpod)
│   │   ├── chat_screen.dart      # StatefulWidget: собирает виджеты, feature flag kEnableQuickPrompts
│   │   ├── models/
│   │   │   ├── chat_message.dart         # ChatMessage: text, isUser, imageUrl, timestamp, liked, blocks(SDUI)
│   │   │   ├── quick_prompt.dart         # QuickPrompt + QuickPromptsLibrary (чипы приветствия)
│   │   │   └── sdui/
│   │   │       └── questionnaire_prompt_models.dart  # SduiQuestion, QuestionnairePromptBlockData, парсинг JSON
│   │   └── widgets/
│   │       ├── chat_app_bar.dart
│   │       ├── chat_bubble.dart          # User/AI пузыри + рендер SDUI блоков через SduiBlockDispatcher
│   │       ├── chat_input_bar.dart       # Текст + микрофон + камера (обычная/галерея/guided capture)
│   │       ├── chat_message_list.dart    # ListView.builder + ListenableBuilder(ChatController)
│   │       ├── chat_welcome.dart         # Приветственный экран + быстрые промпты (чипы)
│   │       ├── message_menu.dart         # BottomSheet: лайк/копировать/повторить/удалить/очистить чат
│   │       ├── new_chat_button.dart      # Кнопка "Новая консультация" (clearChat)
│   │       ├── quick_prompts_section.dart
│   │       ├── typing_indicator.dart
│   │       └── SDUI/
│   │           ├── sdui_block_dispatcher.dart      # Диспетчер: пока только questionnaire_prompt
│   │           ├── questionnaire_prompt_block.dart # Рендер блока анкетирования
│   │           ├── unknown_block.dart              # Fallback для неизвестных block.type
│   │           └── controls/
│   │               ├── qp_buttons_control.dart     # single-select (bool/tri_state/enum)
│   │               ├── qp_free_text_control.dart   # free_text/open_list/free_paragraph
│   │               ├── qp_multi_enum_control.dart  # multi_select chips + Done
│   │               ├── qp_numeric_control.dart     # числовое поле с unit/min/max
│   │               └── qp_plain_label.dart         # Неизвестный тип — просто текст
│   ├── calendar/
│   │   └── calendar_screen.dart    # Заглушка "Coming Soon"
│   ├── photo_capture/
│   │   ├── capture_controller.dart         # ChangeNotifier: CameraController + ML Kit face detection + QualityChecker
│   │   ├── capture_screen.dart             # StatefulWidget: превью + оверлей + индикаторы + хинты + кнопка снятия
│   │   ├── models/
│   │   │   └── capture_result.dart         # CaptureResult: fileBytes, mimeType, qualityMetadata
│   │   ├── services/
│   │   │   ├── face_detector_service.dart  # Singleton FaceDetector (ML Kit, offline, landmarks)
│   │   │   └── quality_checker.dart        # QualityMetrics (score, lighting, sharpness, faceRatio, yaw, pitch)
│   │   └── widgets/
│   │       ├── face_overlay.dart           # Овал лица + цвет рамки (зелёный/красный)
│   │       ├── quality_hint.dart           # Динамический текст подсказки по метрикам
│   │       └── quality_indicators.dart     # 4 индикатора: освещение, ракурс, позиция, дистанция
│   ├── profile/
│   │   ├── profile_screen.dart     # StatefulWidget: header, фото, beauty-профиль, tech info, logout
│   │   └── widgets/
│   │       ├── avatar_picker_sheet.dart
│   │       ├── beauty_profile_section.dart
│   │       ├── photos_section.dart
│   │       ├── profile_header.dart
│   │       └── profile_tiles.dart
│   └── project/
│       ├── project_provider.dart
│       └── project_select_screen.dart
├── debug/
│   └── questionnaire_prompt_preview/   # Preview-экраны для SDUI блоков (dev only)
└── router.dart                       # (дубликат корневого, см. выше)
```

---

## 2. Краткое содержание ключевых файлов

### 2.1 `core/api/api_client.dart` — **Единый HTTP-клиент**

**Синглтон Dio** с интерцепторами:
- `onRequest`: подставляет `Authorization: Bearer <access_token>` из `AppStorage`
- `onError (401)`: авто-refresh через `/app/auth/refresh`, ретрай исходного запроса

**Методы (все `static`):**

| Метод | Назначение | Вход | Выход |
|-------|------------|------|-------|
| `init()` | Регистрация/авторизация пользователя при старте | — | `Future<void>` |
| `_register(appUserId, displayName?, platform?)` | POST `/app/auth/register` | `appUserId`, `displayName?`, `platform='android'` | Сохраняет токены в `AppStorage` |
| `updateDisplayName(displayName)` | Обновление имени (перерегистрация) | `displayName` | `Future<void>` |
| `streamChat(prompt, conversationId?, busySlots?)` | **SSE streaming** POST `/app/chat` | `prompt`, `conversationId?`, `busySlots?` | `Stream<Map<String, dynamic>>` (парсит `data:` строки) |
| `loadHistory(conversationId)` | GET `/app/messages/{id}` | `conversationId` | `List<Map<String, dynamic>>` |
| `getCalendarEvents(category?, activeOnly?)` | GET `/app/calendar/events` | query params | `List<Map<String, dynamic>>` |
| `applyCalendarProposal(events)` | POST `/app/calendar/apply` | `events: List<Map>` | `List<Map>` (созданные события) |
| `updateCalendarEvent(eventId, ...)` | PATCH `/app/calendar/events/{id}` | частичные поля | `Future<void>` |
| `deleteCalendarEvent(eventId)` | DELETE `/app/calendar/events/{id}` | `eventId` | `Future<void>` |
| `syncCalendarEvents(records)` | POST `/app/calendar/sync` | `records` | `Future<void>` |
| `uploadPhoto(fileBytes, mimeType, qualityMetadata?)` | **Multipart** POST `/app/photos` | `Uint8List`, `mimeType`, `qualityMetadata?` | `Map` с `url` |
| `getPhotos()` | GET `/app/photos` | — | `List<Map>` (photos array) |
| `deletePhoto(photoId)` | DELETE `/app/photos/{id}` | `photoId` | `Future<void>` |
| `getBeautyProfile()` | GET `/app/profile` | — | `Map<String, dynamic>` |

**SSE формат (streamChat):**
```
data: {"content": "chunk"}
data: {"blocks": [{...}, ...]}
data: {"calendar_proposal": {"events": [...]}}
data: {"conversation_id": "uuid"}
data: [DONE]
```

---

### 2.2 `core/storage.dart` — **Локальное хранилище**

**Ключи SharedPreferences:**
```
app_user_id         # UUID устройства (генерируется при первом запуске)
user_name           # Имя пользователя (вводится на LoginScreen)
access_token        # JWT access token
refresh_token       # JWT refresh token
active_project_id   # UUID проекта (пока не используется активно)
conversation_id     # ID текущего чата (перезаписывается при новом SSE)
avatar_path         # Локальный путь к аватару
```

**Публичный API:**
| Метод | Описание |
|-------|----------|
| `getOrCreateUserId()` | Вернёт существующий или сгенерирует новый UUID v4 |
| `setUserName(name)` | Сохранить имя |
| `getUserName()` | Прочитать имя (для редиректа в router) |
| `saveTokens(access, refresh)` | Сохранить пару токенов |
| `getAccessToken()` / `getRefreshToken()` | Чтение токенов |
| `saveConversationId(id)` / `getConversationId()` | Текущий диалог |
| `saveAvatarPath(path)` / `getAvatarPath()` | Аватар + `ValueNotifier<String?> avatarNotifier` для реактивного UI |
| `initAvatarNotifier()` | Инициализация нотифаера при старте (вызывается в `main.dart`) |
| `clearUser()` | Полный вайп (logout) + сброс `avatarNotifier` |

---

### 2.3 `core/theme.dart` — **Дизайн-система AURA**

**Цветовые токены (Light / Dark):**
```
Light:          Dark:
bg         #FAF7F5    #1C1414
aiBubble   #F2E8E4    #2A1F1F
userBubble #EDE8E3    #241D1D
surface    #FFFFFF    #221818
accent     #E8A0A0    #E8A0A0 (одинаковый)
textDark   #3D2C2C    #F5EDE8
textSub    #9E7E7E    #8A7070
hint       #B09090    #6A5555
```

**Extension `context.aura`** → `AuraColorScheme` (light/dark автоматически).

**Шрифт:** `CormorantGaramond` (variable font, загружается из assets/fonts).

**Material3** + кастомные `AppBarTheme`, `InputDecorationTheme`, `ElevatedButtonTheme`.

---

### 2.4 `features/chat/chat_controller.dart` — **Мозг чата (ChangeNotifier)**

**Состояние:**
```dart
List<ChatMessage> messages = [];
bool isStreaming = false;
bool isUploadingPhoto = false;
String? conversationId;
TextEditingController inputController;
ScrollController scrollController;
SpeechToText _speech;  // speechAvailable, isListening
Function(int count)? onCalendarApplied;  // callback для SnackBar
```

**Жизненный цикл:**
- `init()` → `_initSpeech()` + `loadHistory()`
- `dispose()` → контроллеры + `_speech.stop()`

**Speech-to-Text:**
- `toggleListening(onFinalResult)` — старт/стоп `listen(localeId: 'ru_RU', listenFor: 30s)`
- Результат пишется в `inputController.text`, при `finalResult` → вызывает `onFinalResult()` (обычно `sendMessage()`)

**История:**
- `loadHistory()` — читает `conversationId` из `AppStorage`, грузит `/app/messages/{id}`, мапит в `ChatMessage`
- При 401/ошибке авторизации — чистит `conversationId` локально

**Отправка сообщения:**
```dart
sendMessage({overrideText?, imageUrl?})
```
1. Добавляет user-сообщение + пустое AI-сообщение в `messages`
2. `isStreaming = true`
3. Вызывает `_streamChat(prompt, conversationId)` (инжектируемый `StreamChatFn` для тестов)
4. Обрабатывает события через `handleStreamEvent(event)`:
   - `calendar_proposal` → `_applyCalendarProposalSilently()` (POST `/app/calendar/apply`, fire-and-forget)
   - `blocks` → обновляет `blocks` последнего AI-сообщения
   - `content` → инкрементально дописывает в `text` последнего AI-сообщения
   - `conversation_id` → сохраняет в `conversationId` + `AppStorage`
5. `catch`: **Политика conversationId** (см. тест `chat_controller_test.dart`):
   - Если `conversationId` был `null` ДО попытки — оставляет `null` (новый разговор не создался)
   - Если `conversationId` был известен — **НЕ обнуляет** (разговор на сервере существует)
6. `finally`: `isStreaming = false`

**Фото:**
```dart
uploadAndSendPhoto(fileBytes, mimeType, prompt, qualityMetadata?)
```
1. `ApiClient.uploadPhoto()` → получает `url`
2. `sendMessage(overrideText: prompt, imageUrl: url)`

**Календарь (silent apply):**
```dart
_applyCalendarProposalSilently(proposal) // fire-and-forget, вызывает onCalendarApplied(count)
```

**Действия с сообщениями:**
- `likeMessage(index)` — toggle `liked`
- `retryMessage(index)` — находит предыдущее user-сообщение, удаляет пару, ресендит
- `deleteMessage(index)` — удаляет одно сообщение
- `clearChat()` — чистит `messages`, `conversationId = null`, `AppStorage.saveConversationId('')`

**Scroll:** `scrollToBottom()` — анимированный скролл к низу (80ms delay + 300ms duration)

---

### 2.5 `features/chat/models/chat_message.dart`

```dart
class ChatMessage {
  final String text;
  final bool isUser;
  final String? imageUrl;
  final DateTime timestamp;
  bool liked;
  final List<Map<String, dynamic>>? blocks;  // SDUI блоки из SSE (questionnaire_prompt)

  ChatMessage copyWith({text, liked, blocks})
}
```
- `blocks` — `null` если бэкенд не прислал, пустой список не приходит (по контракту)

---

### 2.6 `features/chat/widgets/SDUI/` — **Server-Driven UI**

#### `sdui_block_dispatcher.dart`
```dart
static Widget build(block, {required onSendMessage})
```
- Switch по `block['type']`
- **Только `questionnaire_prompt` реализован**
- Остальные (`buttons`, `media`, `link`, `gif`, `calendar_proposal`) — НЕ диспетчеризуются, обрабатываются отдельно в `ChatController`/`ChatBubble`
- Валидация `version == 1`, иначе `UnknownBlock`

#### `questionnaire_prompt_block.dart`
- Рендерит `data.intro` (title), прогресс `1/N`, первый вопрос `questions[0]`
- Делегирует контрол `_buildControl(question)` → соответствующий виджет

#### `questionnaire_prompt_models.dart` — **Парсинг контракта**

**Контракт:** `contracts/sdui_blocks/questionnaire_prompt.schema.json`

**JSON ключи (важно — не совпадают с Dart полями):**
| JSON | Dart поле | Комментарий |
|------|-----------|-------------|
| `version` | `blockVersion` | обязательно, `int` |
| `questionnaire_slug` | `questionnaireSlug` | обязательно |
| `title` | `intro` | опционально, в JSON называется `title` |
| `questions[]` | `questions` | массив объектов |

**Question JSON → Dart:**
| JSON | Dart | Валидация |
|------|------|-----------|
| `answer_key` | `key` | **обязательно**, строка (не `key`!) |
| `type` | `type` | строка, известные: `bool`, `tri_state`, `enum`, `multi_enum`, `numeric`, `open_list`, `free_paragraph` |
| `input_mode` | `inputMode` | строка, известные: `buttons`, `free_text` |
| `label` | `label` | **обязательно**, строка |
| `item_label` | `itemLabel` | опционально (repeating_by_reference) |
| `group_label` | `groupLabel` | опционально |
| `is_revalidation` | `isRevalidation` | bool, default false |
| `options[]` | `options` | `[{value, label}]`, обязательно для `buttons` |
| `multi_select` | `multiSelect` | bool, default false |
| `numeric_constraints` | `numericConstraints` | `{unit?, min?, max?}` |

**`isInteractive`** = `isKnownType && isKnownInputMode` → если `false` рендерится `QpPlainLabel`.

---

### 2.7 `features/chat/widgets/SDUI/controls/` — **Контролы анкетирования**

| Виджет | Тип вопроса | input_mode | Отправляет в чат |
|--------|-------------|------------|------------------|
| `QpButtonsControl` | `bool`, `tri_state`, `enum` (single) | `buttons` | `option.label` (НЕ `value`) |
| `QpMultiEnumControl` | `multi_enum` | `buttons` | `"label1, label2, ..."` (через запятую) |
| `QpNumericControl` | `numeric` | `free_text` | `"{label}: {value}"` (с префиксом label) |
| `QpFreeTextControl` | `open_list`, `free_paragraph` | `free_text` | `"{label}: {text}"` |
| `QpPlainLabel` | неизвестный type/input_mode | — | ничего (только показ label) |

**Важно:** `QpButtonsControl` при тапе сразу вызывает `onSendMessage(option.label)`.
**Важно:** `QpMultiEnumControl` — чекбоксы (FilterChip) + кнопка "Готово" → собирает выбранные labels.

---

### 2.8 `features/photo_capture/` — **Guided Capture (образцовая съёмка)**

#### `capture_controller.dart`
```dart
CameraController? _cameraController;
bool _isCameraInitialized;
bool _isProcessing;
QualityMetrics? _currentMetrics;
bool _isGoodQuality;
String? _errorMessage;

initializeCamera()           // front camera, ResolutionPreset.medium
analyzeCurrentFrame()        // takePicture → decode → ML Kit detectFaces → QualityChecker.analyze()
capturePhoto() → CaptureResult?  // если isGoodQuality, возвращает bytes + qualityMetadata
```

#### `quality_checker.dart` — **Метрики качества**

```dart
QualityMetrics {
  score: double        // 0.0–1.0 итоговый
  lighting: String     // 'dim' | 'good' | 'overexposed'
  sharpness: double    // 0.0–1.0 (градиент пикселей)
  faceRatio: double    // площадь лица / площадь кадра
  yaw: double          // поворот головы по Y (градусы)
  pitch: double        // наклон головы по X (градусы)

  isGoodQuality: bool  // score>=0.7 && lighting=='good' && sharpness>=0.5 && faceRatio>=0.3 && |yaw|<=15 && |pitch|<=15
}
```

**Пороги (hardcoded):**
- Освещение: `<80` dim, `>220` overexposed, иначе good
- Резкость: средний градиент / 20, clamp 0..1
- Face ratio: 0.3–0.7 идеально, 0.2+ приемлемо
- Углы: |yaw|+|pitch| <= 30° суммарно

#### `face_detector_service.dart`
- Singleton `FaceDetector` (ML Kit)
- `enableLandmarks: true`, `minFaceSize: 0.15`
- `detectFaces(InputImage)` → `List<Face>`
- `dispose()` → `detector.close()`

#### `capture_screen.dart`
- `CameraPreview` + `FaceOverlay` (овал, цвет по `isGoodQuality`)
- `QualityIndicators` (4 круга: освещение, ракурс, позиция, дистанция)
- `QualityHint` (текстовая подсказка: "Включите яркий свет", "Отодвиньте телефон" и т.д.)
- Кнопка "СНЯТЬ" активна только при `isGoodQuality`
- При успехе `Navigator.pop(context, CaptureResult)`

---

### 2.9 `features/profile/profile_screen.dart`

**Загружает при инициализации:**
- `_loadLocal()` — имя, user_id из `AppStorage`
- `_loadPhotos()` — `ApiClient.getPhotos()` → список фото
- `_loadProfile()` — `ApiClient.getBeautyProfile()` + `GET /app/profile/status` (completion %)

**UI:**
- `ProfileHeader` — аватар, имя, completion %, фото
- `PhotosSection` — сетка фото + удаление (confirm dialog + `ApiClient.deletePhoto`)
- `BeautyProfileSection` — отображение профиля (skin_type, concerns, etc.)
- Tech section — платформа, подписка, device ID (первые 8 chars)
- Logout → `AppStorage.clearUser()` + `context.go('/login')`

---

### 2.10 `features/auth/login_screen.dart`

- `TextField` для имени (autofocus, textCapitalization.words)
- Кнопка "Продолжить" → `AppStorage.setUserName` + `ApiClient.updateDisplayName` → `context.go('/chat')`
- При ошибке сети — имя сохраняется локально, навигация всё равно происходит

---

### 2.11 `router.dart` — **Навигация**

```dart
initialLocation: '/login'
redirect: (context, state) {
  final name = await AppStorage.getUserName();
  if (name != null && onLogin) return '/chat';
  if (name == null && !onLogin) return '/login';
}
```

**Роуты:**
| Path | Screen | Transition |
|------|--------|------------|
| `/login` | `LoginScreen` | default |
| `/chat` | `ChatScreen` | default |
| `/calendar` | `CalendarScreen` | Slide from left (300ms) |
| `/profile` | `ProfileScreen` | Slide from right (300ms) |

---

## 3. Важный контекст для задач

### 3.1 Контракты с бэкендом (VB-backend)

**Базовый URL:** `https://vibe-bit.ru/api` (в `AppConstants.baseUrl`)

**Эндпоинты, используемые мобильным приложением:**

| Метод | Путь | Описание |
|-------|------|----------|
| POST | `/app/auth/register` | Регистрация/получение токенов (app_user_id, display_name, platform) |
| POST | `/app/auth/refresh` | Рефреш access_token (refresh_token) |
| POST | `/app/chat` | **SSE streaming** чат (prompt, stream=true, conversation_id?, busy_slots?) |
| GET | `/app/messages/{conversationId}` | История сообщений |
| GET | `/app/calendar/events` | Список событий (active_only, category?) |
| POST | `/app/calendar/apply` | Принять предложение календаря от AI (events[]) |
| PATCH | `/app/calendar/events/{id}` | Обновление события |
| DELETE | `/app/calendar/events/{id}` | Удаление события |
| POST | `/app/calendar/sync` | Синхронизация с device_calendar |
| POST | `/app/photos` | Multipart загрузка фото (file, quality_metadata?) |
| GET | `/app/photos` | Список фото пользователя |
| DELETE | `/app/photos/{id}` | Удаление фото |
| GET | `/app/profile` | Beauty-профиль пользователя |
| GET | `/app/profile/status` | Статус заполненности профиля (completion %) |

**SSE Event Types (из `/app/chat`):**
```json
// Текстовый чанк
{"content": "текст"}

// SDUI блоки (questionnaire_prompt и др.)
{"blocks": [{"type": "questionnaire_prompt", "version": 1, "questionnaire_slug": "...", "title": "...", "questions": [...]}]}

// Календарное предложение (отдельно от blocks!)
{"calendar_proposal": {"events": [{"title": "...", "category": "...", "recurrence": "...", "duration_minutes": 30, "notes": "..."}]}}

// ID разговора (приходит в конце или в начале)
{"conversation_id": "uuid"}

// Конец стрима
[DONE]
```

### 3.2 Feature Flags

```dart
// lib/features/chat/chat_screen.dart
const bool kEnableQuickPrompts = false;  // Чипы быстрых промптов (отключены маркетингом)
```

### 3.3 Тесты (существующие)

| Файл | Что тестирует |
|------|---------------|
| `test/features/chat/chat_controller_test.dart` | Политика `conversationId` при обрыве SSE (null vs сохранённый) + логирование |
| `test/features/chat/questionnaire_prompt_block_test.dart` | 11 фикстур SDUI блоков через реальный `ChatBubble` → `SduiBlockDispatcher` → контролы |
| `test/features/chat/models/sdui/questionnaire_prompt_models_test.dart` | Парсинг моделей (unit-тесты) |

**Фикстуры:** `test/fixtures/questionnaire_prompt.mock.json` — 11 вариантов блоков (bool, tri_state, enum, multi_enum, numeric, open_list, free_paragraph, multi_question_progress, revalidation, invalid_question_type, invalid_block_version).

### 3.4 Известные ограничения / Technical Debt

1. **`chat_provider.dart` пуст** — Riverpod не используется для чата, всё на `ChangeNotifier`
2. **SDUI диспетчер неполный** — только `questionnaire_prompt`; `calendar_proposal` обрабатывается в `ChatController` отдельно, `buttons/media/link/gif` — не рендерятся
3. **`calendar_screen.dart` — заглушка** ("Coming Soon"), реальный календарь не реализован
4. **`project_select_screen.dart` / `project_provider.dart`** — заготовки, проект пока не переключается (hardcoded `BEAUTY_PROJECT_ID` на бэкенде)
5. **Нет error boundary / crashlytics** — ошибки логируются в `debugPrint`
6. **`speech_to_text`** — только `ru_RU`, нет переключения локали
7. **Guided capture** — работает только с фронтальной камерой, нет переключения камер
8. **QualityChecker** — пороги захардкожены, не конфигурируются с бэкенда

### 3.5 Архитектурные паттерны

- **Dependency Injection через конструктор** — `ChatController(streamChat: ...)` для тестируемости
- **Repository pattern не используется** — `ApiClient` — прямые static методы (но с интерцепторами)
- **Reactive UI через `ListenableBuilder(ChatController)`** — все виджеты чата подписаны на контроллер
- **ValueNotifier для аватара** — `AppStorage.avatarNotifier` (без Riverpod)
- **Feature flag константа** — `kEnableQuickPrompts` (compile-time)

### 3.6 Файлы, которые НЕ трогать без причины

| Файл | Причина |
|------|---------|
| `core/api/api_client.dart` | Критический путь: auth, SSE, refresh token — изменения требуют полного регресса |
| `core/storage.dart` | Ключи SharedPreferences — миграция данных пользователей |
| `features/chat/chat_controller.dart` | Сложная логика SSE + conversationId policy + тесты зависят от поведения |
| `features/chat/models/sdui/questionnaire_prompt_models.dart` | Контракт с бэкендом — парсинг должен совпадать с JSON схемой |
| `core/l10n/app_localizations.dart` | Интерфейс локализации — добавление строки требует обновления 3 файлов (en/ru/kk) |

### 3.7 Файлы, которые часто меняются при задачах

| Задача | Файлы |
|--------|-------|
| Новый SDUI блок | `sdui_block_dispatcher.dart`, новый виджет в `controls/`, модель в `questionnaire_prompt_models.dart` |
| Изменение полей чата | `chat_message.dart`, `chat_bubble.dart`, `chat_controller.dart` (handleStreamEvent) |
| Новый API эндпоинт | `api_client.dart` + соответствующий экран/виджет |
| Изменение валидации фото | `quality_checker.dart`, `capture_controller.dart`, `capture_screen.dart` |
| Локализация | `l10n_ru.dart`, `l10n_en.dart`, `l10n_kk.dart`, `app_localizations.dart` |

---

## 4. Запуск и разработка

```bash
# Зависимости
flutter pub get

# Запуск (Android/iOS/Web)
flutter run

# Тесты
flutter test                                    # все
flutter test test/features/chat/chat_controller_test.dart
flutter test test/features/chat/questionnaire_prompt_block_test.dart

# Анализ
flutter analyze

# Генерация иконок (после смены assets/images/Aura_Beauty_Splash.png)
flutter pub run flutter_launcher_icons:main
```

**Минимальные версии:** Android API 21+, iOS 12+ (camera, ML Kit требуют).

---

## 5. Ссылки на связанные документы (в репозитории VB-backend)

- `VB-infra/docs/ProjectFull.txt` — полная спецификация бэкенда
- `VB-infra/docs/KB v3Phase1-3.txt` — KB v3/v4 импорт (используется профилем/фото)
- `VB-backend/app/routers/app_chat.py` — мобильный чат эндпоинт (SSE контракт)
- `VB-backend/app/services/chat_engine.py` — единый agentic движок (Lab + будущая миграция mobile)
- `VB-backend/app/services/app_tools.py` — тулы агента (profile, calendar, photos)
- `contracts/sdui_blocks/questionnaire_prompt.schema.json` — JSON Schema SDUI блока

---

> **Примечание:** Этот документ — базвый контекст. При изменении архитектуры (миграция на `chat_engine`, добавление новых SDUI блоков, включение календаря) — обновляй соответствующие разделы.