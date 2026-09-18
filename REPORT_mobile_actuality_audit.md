# REPORT: аудит актуальности beauty_mobile относительно мастер-документов

Дата: 2026-09-09
Тип сессии: **только аудит, код не менялся.** Ничего не закоммичено в `lib/`,
изменение единственное — сам этот файл.

Источники сверки:
- `vb_docs` (read-only): `AGENT_RULES_orchestrator.md`, `ProjectFull.md`,
  `ProjectBeauty.md`, `universal_dialog_engine.md`. `ProjectChangelog.md` —
  по инструкции не смотрел.
- `VB-backend` (read-only): реальный код `routers/app_chat.py`,
  `routers/app_photos.py`, `services/chat_blocks.py`, `services/ui_block_tools.py`,
  `contracts/sdui_blocks/*.schema.json` — как источник фактического контракта
  там, где проза в `vb_docs` не давала однозначного ответа.
- `beauty_mobile` (проверяемый репозиторий), включая собственные локальные
  документы `AURA_mobile.md`, `instructions_080926.md`.

`flutter test` **не прогонялся** — в песочнице сессии нет Flutter SDK и нет
сетевого доступа к его дистрибутиву (allowlist ограничен git/npm/pip/cargo
registries). Весь анализ ниже — статический (чтение кода + grep), не
compile-time/runtime проверка. Рекомендация: прогнать `flutter analyze` и
`flutter test` в CI/окружении оркестратора перед тем, как опираться на этот
отчёт как на полную гарантию отсутствия регрессий.

---

## 🔴 Критичные несоответствия (NON-NEGOTIABLE)

### 1. Захардкоженный base URL бэкенда
`lib/core/constants.dart`:
```dart
class AppConstants {
  static const String baseUrl = 'https://vibe-bit.ru/api';
}
```
Прямое нарушение абсолютного запрета «никаких захардкоженных... base URL
бэкенда... в коде — только через конфиг/окружение сборки». Никакого
`--dart-define`, `.env`, flavor-конфига или иной внешней инъекции в
репозитории нет вообще (проверено — ни одного упоминания
`fromEnvironment`/`dotenv`/`Platform.environment` в `lib/`).
**Нужен отдельный бриф**: скорее всего `String.fromEnvironment('API_BASE_URL',
defaultValue: ...)` + обновление CI/build-скриптов, а не тривиальная правка
одной строки — трогать самостоятельно не стал, вне объёма аудита.

### 2. Legal Consent Gate v4 не покрывает путь загрузки фото
Бэкенд (`routers/app_photos.py`, докстринг модуля) прямым текстом фиксирует
контракт:
> `check_medical()` — вызов перед приёмом файла. 403 с
> `{"blocked_reason": "medical_consent_required"}` — **мобильный BRIEF
> трактует этот 403 как модалку гейта, не error-toast.**

Фактическое поведение клиента (`chat_input_bar.dart::_startGuidedCapture()` /
`_pickPhoto()`): любая ошибка загрузки, включая этот самый 403, ловится общим
`catch (e)` и превращается в обычный `SnackBar` с текстом `photoUploadFailed`
— то есть ровно тот error-toast, который бэкенд-бриф явно исключает как
неверную трактовку.

Для сравнения — путь через чат (`legal_consent_gate` SDUI-блок,
`chat_controller_legal_consent.dart`) этот гейт обрабатывает правильно
(структурированный HTTP мимо LLM, модалка, а не toast). На пути фото та же
модель не воспроизведена вообще — это не «стилистическое» расхождение, это
прямое цитируемое расхождение с уже написанным бэкенд-контрактом.
**Открытый пункт для брифа**: `uploadAndSendPhoto()`/вызывающий UI должны
парсить `error.response.data['detail']['blocked_reason'] ==
'medical_consent_required'` (тот же паттерн, что `legal_consent_errors.dart`
уже применяет для `underage`/`declined`) и показывать существующий gate-UI
вместо toast.

### 3. State management расходится с архитектурным мандатом
Правило: «State Management: строго Riverpod (Providers, Notifiers) —
никаких мутируемых глобальных синглтонов»; «Dependency Injection: через
Riverpod Providers, никаких зависимостей, создаваемых внутри классов
напрямую».

Фактически:
- `ChatController` и `CaptureController` — `extends ChangeNotifier`, не
  Riverpod `Notifier`/`StateNotifier`.
- `ApiClient` — статический класс со статическим `final Dio _dio` внутри,
  создаваемым напрямую (не через провайдер) — buквально «зависимость,
  создаваемая внутри класса напрямую», плюс мутируемое глобальное состояние
  (interceptors добавляются один раз в `init()`).
- Riverpod (`Provider`/`ConsumerWidget`/`NotifierProvider`) реально
  используется только в `calendar/providers/*`, `core/push/push_providers.dart`,
  частично в `chat_screen.dart`/`login_screen.dart`.

Это, судя по `AURA_mobile.md` (см. структуру `ChatController (ChangeNotifier:
messages, conversationId...)` в `ProjectBeauty.md`), **унаследованная,
задокументированная и уже принятая архитектура**, а не новый косяк текущей
сессии — но она прямо противоречит текущей формулировке мандата по стеку.
Не переписываю самостоятельно (это не микро-правка, а миграция ядра чата) —
**эскалирую оркестратору**: либо (а) официально зафиксировать
`ChangeNotifier`+static `ApiClient` как принятое исключение для legacy-кода
чата/фото (с явной пометкой в `ProjectBeauty.md`), либо (б) завести отдельный
бриф на миграцию на Riverpod `Notifier`.

---

## 🟡 Несоответствия среднего приоритета

### 4. `option.label` вместо `option.value` на кнопочных safety-вопросах
`contracts/sdui_blocks/questionnaire_prompt.schema.json` (`submit_contract`)
фиксирует: submit ожидает мапу `answer_key → value` (машинное значение из
`options[].value`), собираемую **LLM** по итогам тапов пользователя.
Фактически `QpButtonsControl._handleTap()` отправляет в чат
`option.label` (отображаемый, переведённый текст типа «не уверена»), не
`option.value` — это осознанно задокументировано в самом коде
(`// Тап сразу отправляет option.label как обычное сообщение чата —
option.value на сервер отдельно не уходит`) и совпадает с описанием в
`AURA_mobile.md`.

Технически работает, потому что тот же LLM-ход видит и вопрос с его
`options`, и текстовый ответ пользователя, и сам вызывает
`submit_repeating_answers` с правильным `value`. Но это прямо противоречит
принципу из `universal_dialog_engine.md` §2: «safety-гейт не может зависеть
от LLM-экстракции свободного текста — цена ошибки для медицински значимых
решений слишком высока» — button-тап по факту всё ещё проходит через слой
интерпретации LLM, просто с более узким/предсказуемым входом, чем
произвольный текст. Не переквалифицирую это в баг клиента (контракт
`submit_repeating_answers` в принципе не описывает альтернативного
структурированного HTTP-пути в обход LLM, в отличие от
`acceptSchedulingSlot`/`submitMedicalConsent`) — **фиксирую как
архитектурный вопрос к оркестратору**: нужен ли для `restriction:*`/
`symptom:*` отдельный структурированный submit-эндпоинт по аналогии с Флоу 4
accept, или текущая LLM-опосредованная схема признаётся приемлемым
компромиссом.

### 5. `buttons`/`media`/`link`/`gif` не диспетчеризуются, при этом `show_buttons` реально засеян для Beauty
`ProjectFull.md`: `show_buttons` ⚠ «Засеян ТОЛЬКО для Beauty — точечный
INSERT» — то есть в реальном Beauty-диалоге LLM МОЖЕТ вызвать этот tool и
прислать `{"type": "buttons", "buttons": [...]}" внутри `{blocks}`.
`SduiBlockDispatcher.build()` для этого типа не имеет `case` и падает в
`default → UnknownBlock` — приложение не крашится (fallback соблюдён), но
пользователь увидит нейтральную заглушку вместо реальных кнопок там, где
backend уже способен их прислать. `media`/`link`/`gif` пока не засеяны ни
для одного проекта (по `ProjectFull.md`), поэтому для них риск чисто
теоретический — а вот `buttons` для Beauty уже практический пробел.

### 6. Стрёмные/мёртвые файлы в репозитории
- `lib/features/auth/login_screen.dart.bak` — 171-строчный backup закоммичен
  в git (виден с самого `initial commit`). Не должен лежать в репозитории.
- Три 0-байтных stub-файла без единой строки кода:
  `lib/features/auth/auth_provider.dart`,
  `lib/features/chat/chat_provider.dart`,
  `lib/features/project/project_provider.dart` — судя по всему, заготовки
  под Riverpod-миграцию (см. п.3 выше), которые так и не заполнили.
- `lib/features/project/project_select_screen.dart` — не подключён ни к
  одному `GoRoute` в `router.dart` (недостижим), при этом содержит
  захардкоженную русскую строку `'Выбор проекта — в разработке'` — нарушение
  i18n-правила, только на мёртвом коде, поэтому классифицирую как
  low-priority housekeeping, а не активный баг.

### 7. `AURA_mobile.md` (собственный документ репозитория) отстаёт от кода
Пишет буквально: «Только `questionnaire_prompt` реализован. Остальные
(`buttons`, `media`, `link`, `gif`, `calendar_proposal`) — НЕ
диспетчеризуются» — но реальный `sdui_block_dispatcher.dart` уже
диспетчеризует `calendar_proposal`, `calendar_event_confirmation` и
`legal_consent_gate`. Документ не обновлён после Флоу 4/Legal Consent Gate
v4 брифов. Рекомендация оркестратору: включить `AURA_mobile.md` в цикл
синхронизации памяти (`AGENT_RULES_orchestrator.md` §4), он явно живёт
отдельно от `ProjectBeauty.md`.

### 8. `ProjectBeauty.md` частично устарел по платформе/стеку
- Написано «Платформа: Android (iOS в планах)» — но в репозитории есть
  полноценный `ios/Runner.xcodeproj` с корректным bundle id
  (`ru.vibebit.vbMobile`), включая `RunnerTests`. Возможно, это осознанно
  «scaffold без реального релиза», но текущая формулировка звучит как «iOS
  ещё не начат», что уже не так буквально.
- Список пакетов стека не включает уже реально используемые
  `camera`, `google_mlkit_face_detection`, `image`, `permission_handler`
  (guided capture), `firebase_core`/`firebase_messaging`/
  `flutter_local_notifications` (push), `url_launcher` (legal document
  ссылки). Список в документе описывает более раннее состояние проекта.

### 9. Ссылки на `CONTRACT_flow4_scheduling_v1.md` и `CONTRACT_legal_consent_gate_v4.md` — файлы не найдены
Оба документа активно и детально цитируются в десятках комментариев кода (и
backend, и mobile) как источник истины по конкретным параграфам (§2, §3,
§4a, §6, §7...), но **физически не присутствуют** ни в `vb_docs`, ни в
`VB-backend` в доступной мне read-only копии. Возможно, они существуют вне
этих трёх репозиториев (например, отдельная папка `contracts/` вне
`vb_docs`) — не могу исключить, что просто не туда посмотрел. Если файлов
действительно нет ни в одном репозитории — это разрыв «единственного
источника правды» (`AGENT_RULES_orchestrator.md` §1): код на обеих сторонах
границы ссылается на параграфы документа, который не хранится централизованно.

---

## ✅ Подтверждено как соответствующее контракту

- **SSE-парсинг чата** — `ChatController.handleStreamEvent()` корректно
  обрабатывает реальную последовательность бэкенда
  (`{content}` чанками → `{blocks}?` → `{calendar_proposal}?` →
  `{conversation_id}` → `[DONE]`), включая аддитивное расширение с
  `{blocks}`, подтверждённое напрямую по коду `routers/app_chat.py`.
  Комментарии в коде правильно различают старый `calendar_proposal`
  passthrough (`propose_calendar_plan`) и новый `calendar_proposal` v2
  SDUI-блок внутри `{blocks}` — оба канала не перепутаны.
- **`SduiBlockDispatcher`** для реализованных типов (`questionnaire_prompt`,
  `calendar_proposal`, `calendar_event_confirmation`, `legal_consent_gate`)
  — корректный `UnknownBlock`-fallback на неизвестный/несовместимый
  `version`, ни один кейс не роняет рендер.
  Все проверены на нижнем уровне (`FormatException` → `UnknownBlock`, не
  необработанное исключение).
- **Разделение слоёв API** — ни одного прямого `dio.get/post/...` или
  `Dio()` вне `core/api/api_client.dart` и
  `core/api/legal_consent_api_client.dart`.
- **`uploadPhoto` не шлёт `conversation_id`** — и это **правильно**:
  фактический эндпоинт `POST /api/app/photos` (см. `app_photos.py`) вообще
  не принимает такое поле сейчас (только `file`, `quality_metadata`).
  Инструкция явно требует не имитировать эту связь раньше, чем контракт это
  подтвердит — клиент этому следует.
- **Календарь read-only на клиенте** — в `features/calendar/` нет ни
  одного вызова `updateCalendarEvent`/`deleteCalendarEvent`/
  `syncCalendarEvents`; вся мутация записей — только через чат
  (negotiation loop Флоу 4), что соответствует продуктовому решению из
  `ProjectBeauty.md`.
- **Приём слота (`acceptSchedulingSlot`) и medical-consent (`submitMedicalConsent`)**
  — оба реализованы как структурированный HTTP мимо `streamChat()`/LLM,
  как и требует контракт (`universal_dialog_engine.md` §9, Legal Consent
  Gate v4), с корректной политикой «никогда не бросает исключение наружу,
  ошибка сообщается локальным сообщением в чат».
- **Лимит 300–400 строк на файл** — соблюдён по всему `lib/`; максимум
  сейчас — `chat_controller.dart`, 392 строки (осознанно держится под
  потолком, часть логики уже вынесена в
  `chat_controller_legal_consent.dart` extension отдельным файлом именно
  по этой причине — задокументировано в самом файле).
- **Казахская локализация** — `L10nKk extends L10nEn`, покрывает 31 из 181
  ключа, остальные консervативно наследуются от английского. Это не
  случайный пробел, а явно самоописанное промежуточное состояние
  («наследует английский до появления переводчика», с пометкой «черновой
  перевод, требует вычитки носителем» на части готовых ключей) — не
  классифицирую как дефект.
- **Хардкод русских UI-строк** — не найден в живых (достижимых через
  `router.dart`) экранах; единственная находка — на мёртвом
  `ProjectSelectScreen` (см. п.6).

---

## ℹ️ Наблюдения без явного вердикта (на усмотрение оркестратора)

- Тестовое покрытие (16 файлов в `test/`) плотное для SDUI/legal_consent/
  chat_controller, но отсутствует для: `sdui_block_dispatcher.dart` как
  таковой (тестируются отдельные блоки, не сам dispatcher/switch),
  `api_client.dart`, `calendar_events_provider.dart`, `photo_capture/`
  (кроме моделей), profile-виджетов. Не блокирующее, но стоит учитывать при
  приоритизации следующих брифов.
- `android/app/google-services.json` закоммичен в репозиторий. Формально не
  секрет (публичные app-идентификаторы Firebase), но обычно такие файлы
  либо не коммитят, либо коммитят осознанно — уточнить, что это осознанное
  решение, а не случайность.
- В `pubspec.yaml` `flutter_launcher_icons.ios: false` — согласуется с
  «iOS в планах» с точки зрения релизной готовности (иконки не
  сгенерированы), даже при наличии Xcode-проекта.

---

## Рекомендуемые следующие шаги (не выполнены в этой сессии — только аудит)

1. Бриф на вынос `baseUrl` в конфиг сборки (`--dart-define` + CI).
2. Бриф на обработку `medical_consent_required` (403) на пути
   `uploadAndSendPhoto()` — переиспользовать существующий gate-UI вместо
   toast.
3. Решение оркестратора по п.3 (State management) — зафиксировать legacy-
   исключение или завести миграционный бриф.
4. Решение оркестратора по п.4 (`option.label` vs `option.value`) —
   принять как компромисс или завести структурированный submit-путь.
5. Точечный бриф на `case 'buttons':` в `SduiBlockDispatcher` — раз tool
   реально засеян для Beauty.
6. Housekeeping: удалить `.bak`-файл, три пустых stub-провайдера,
   недостижимый `ProjectSelectScreen` (или доделать и подключить к роутеру,
   если он ещё нужен).
7. Обновить `AURA_mobile.md` и раздел «МОБИЛЬНОЕ ПРИЛОЖЕНИЕ AURA» в
   `ProjectBeauty.md` — список диспетчеризуемых блоков, платформенный
   статус iOS, полный список пакетов стека.
8. Уточнить местонахождение `CONTRACT_flow4_scheduling_v1.md` и
   `CONTRACT_legal_consent_gate_v4.md` — либо добавить в `vb_docs`, либо
   указать актуальное расположение.
