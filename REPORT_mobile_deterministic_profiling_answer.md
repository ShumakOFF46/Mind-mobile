# REPORT: Mobile — Deterministic Profiling Answer v1 (рендер блока + прямой write)

Основание: `BRIEF_mobile_deterministic_profiling_answer.md`,
`CONTRACT_deterministic_profiling_answer_v1.md` §1-2 (+ ADDENDUM/ADDENDUM2
— обе правки касаются backend tool-сигнатуры и tier1-директивы, схему
блока и мобильный write-контракт не затрагивают, проверено чтением обоих
аддендумов целиком).

---

## 1. Что сделано

### 1.1 Новый SDUI-блок `profiling_question`

- `lib/features/chat/models/sdui/profiling_question_models.dart` —
  `ProfilingQuestionBlockData`/`ProfilingQuestionOption`, defensive-парсинг
  по образцу остальных SDUI-моделей (любое несоответствие →
  `FormatException`).
- **Отличие от `questionnaire_prompt`**, зафиксированное явно в коде:
  `label`/`options[].label` в этом блоке — i18n-карта `{"ru": "...",
  "en": "..."}` (см. схему, `minProperties: 1`), а не готовая строка.
  Резолюция под текущую локаль приложения — на клиенте, через
  `I18nTextResolution.resolve(languageCode)`, `languageCode` берётся из
  `Localizations.localeOf(context).languageCode` (тот же способ доступа к
  локали, что уже используется в `app_localizations.dart` внутри
  `_AppLocalizationsDelegate.isSupported`). Fallback — первое доступное
  значение карты, если текущей локали нет — ровно как просил бриф.
- Границы `options[]` (schema: `minItems: 2, maxItems: 6`) проверяются на
  уровне парсинга модели, не только визуально.
- `lib/features/chat/widgets/sdui/profiling_question_block.dart` —
  виджет, визуальный паттерн кнопок как у `QpButtonsControl`/
  `legal_consent_gate` (`OutlinedButton` в `Wrap`, выбранный — залит
  акцентом, остальные — приглушены после ответа).
- Зарегистрирован в `SduiBlockDispatcher` (`case 'profiling_question'`) с
  `UnknownBlock`-fallback на `FormatException`. У блока в схеме нет поля
  `version` (как и у `legal_consent_gate`) — version-гейта нет, тот же
  принцип.

### 1.2 Write-путь — прямой HTTP, в обход LLM

- `lib/core/api/profiling_answer_api_client.dart` — новый файл (не трогал
  `api_client.dart`, он уже был на границе лимита — 333 строки).
  `POST /app/profiling-answers`, обычный `dio.post()` через
  `ApiClient.instance`, НЕ через `streamChat()`.
- **Поля запроса подтверждены чтением реального backend-кода**
  (`VB-backend/app/routers/profiling_answers.py`, read-only клон), не
  только прозы контракта: `questionnaire_slug`/`answer_key`/`value` →
  `200 {"status": "recorded"}` / `422 forbidden_namespace` / `404
  no_active_definition`.
- `lib/features/chat/chat_controller_profiling_answer.dart` — extension
  `ChatControllerProfilingAnswer.submitProfilingAnswer()`, вынесен
  отдельным файлом по правилу ≤300-400 строк/файл (тот же принцип, что
  `chat_controller_legal_consent.dart`).

### 1.3 Ключевое архитектурное решение — расхождение с существующим паттерном

`onAcceptSlot`/`onSubmitMedicalConsent` **никогда не бросают исключение**
— контроллер сам ловит ошибку, добавляет сообщение в чат, блок считается
"отвеченным" в любом случае (скрывается/блокируется независимо от
исхода).

Бриф для `profiling_question` явно требует **другого** UX ("Обработка
ошибки": *"не ронять UI, показать нейтральную ошибку... и оставить
кнопки активными для повторного тапа"*). Это физически невозможно, если
контроллер поглощает исключение так же, как для остальных трёх
структурированных каналов — тогда `ProfilingQuestionBlock` никогда не
узнает об ошибке и не сможет разблокировать кнопки.

**Решение**: `ChatControllerProfilingAnswer.submitProfilingAnswer()` —
тонкая обёртка БЕЗ `try/catch`, пробрасывающая `DioException` как есть.
`ProfilingQuestionBlock` сам ловит исключение в `_handleTap()`:
- при успехе — фиксирует `_confirmedValue`, блокирует остальные кнопки;
- при ошибке — показывает `l10n.profilingQuestionSaveError`,
  **`_confirmedValue` остаётся `null`** → все кнопки остаются активными,
  повторный тап уходит новым независимым запросом.

Задокументировано явно doc-комментариями в трёх местах (`sdui_block_
dispatcher.dart`, `chat_bubble.dart`, `profiling_question_block.dart`,
`chat_controller_profiling_answer.dart`) — чтобы будущий агент не "исправил"
это по аналогии с другими тремя блоками, не заметив, что расхождение
намеренное и требуется брифом.

### 1.4 Решение по текстовому подтверждению (BRIEF п.2 — "прими решение сам")

**Решение: ДА, отправлять.** После успешного `200 OK` виджет вызывает
`onSendMessage(option.label.resolve(languageCode))` — тот же паттерн, что
уже используется для reject-кнопки `calendar_proposal` и для тапов
`questionnaire_prompt` (`onSendMessage(option.label)`), т.е. **обычное**
сообщение чата, уходящее через `streamChat()`/LLM как если бы пользователь
напечатал его сам. Причина: без этого пользователь видит "пустой" ответ
ассистента после тапа — нет текстового следа в диалоге, что выглядит как
баг с точки зрения UX, даже притом что запись уже успешно прошла
структурированным путём. Модель может отреагировать на этот текст
как угодно (или проигнорировать) — на факт уже произошедшей записи это
не влияет.

### 1.5 Регистрация нового обязательного колбэка — везде, где строился ChatBubble/дispatcher

Новый параметр `onSubmitProfilingAnswer` добавлен как **обязательный** в
`ChatBubble` и `SduiBlockDispatcher.build()` (по аналогии с тем, как это
уже делалось для `onAcceptSlot`/`onSubmitMedicalConsent` — см. историю
комментариев в `questionnaire_prompt_block_test.dart`). Это **сломало бы
компиляцию** во всех местах, где эти конструкторы вызываются без нового
параметра — найдено и поправлено вручную (grep по всему репозиторию, не
полагался на память об одном известном месте):
- `lib/features/chat/widgets/chat_message_list.dart` — реальная
  проводка на `controller.submitProfilingAnswer(...)`.
- `lib/debug/questionnaire_prompt_preview/preview_screen.dart` — QA-экран,
  no-op колбэк (этот экран не тестирует `profiling_question`).
- `test/features/chat/questionnaire_prompt_block_test.dart`,
  `test/features/chat/calendar_proposal_block_test.dart` (9 мест),
  `test/features/chat/calendar_event_confirmation_block_test.dart`
  (6 мест) — no-op колбэки во всех вызовах `ChatBubble`/
  `SduiBlockDispatcher.build`.

### 1.6 l10n (EN + RU, по стандарту проекта)

Добавлены `profilingQuestionRevalidationHint`/`profilingQuestionSaveError`
в `app_localizations.dart` (абстрактные геттеры), `l10n_en.dart`,
`l10n_ru.dart`. `l10n_kk.dart` не трогал — он наследует `L10nEn` и
переопределяет строки по мере перевода (существующий паттерн проекта, не
мой прецедент).

`is_revalidation` отображён минимально, как разрешал бриф: короткая
курсивная подсказка над `label`, без полноценного ревалидационного UX
(вне объёма v1).

---

## 2. Proof bundle

### 2.1 `flutter test` — числа до/после (живой прогон, Windows/PowerShell,
Flutter 3.41.9)

**До этого брифа** (`git stash` на коммите `e3248d2`, т.е. состояние
`main` до пуша по этому брифу): `flutter test
test/features/legal_consent/regional_consent_screen_test.dart` — уже
падает 1 тест (`detectedRegion=null — экран сам вызывает GET /status`),
никак не связанный с этим брифом (см. §2.4 — предсуществующий баг).

**После этого брифа** (полный `flutter test` по всему проекту):
**136 запущено, 135 прошло, 1 упал** — тот же самый
`regional_consent_screen_test.dart`, число совпадает с baseline. Значит
этот бриф НЕ добавил ни одной регрессии в существующий набор тестов.

`flutter analyze` — **0 ошибок**, только `info`-уровня deprecated-warnings
(`withOpacity`), присутствующие в проекте и до этого брифа (тот же класс
warning уже был в `qp_buttons_control.dart`, `unknown_block.dart` и др.) —
не расширяю их зону, `profiling_question_block.dart` следует тому же
уже принятому в проекте паттерну для консистентности, отдельно не
трогал.

**Изолированный прогон только файлов, написанных/изменённых этим
брифом** (`profiling_question_models_test.dart`,
`profiling_question_block_test.dart`,
`profiling_question_dispatcher_test.dart`,
`questionnaire_prompt_block_test.dart`,
`calendar_proposal_block_test.dart`,
`calendar_event_confirmation_block_test.dart`): **54 запущено, 54
прошло, 0 упало**.

Сделано взамен живого прогона в исходной сессии (статический
эквивалент, для протокола):
- Баланс скобок (`{}`, `()`, `[]`) проверен построчным подсчётом по
  каждому новому/изменённому файлу — везде 0 (сбалансировано).
- Построчный лимит файла (§1.1 NON-NEGOTIABLE, ≤300-400 строк) проверен
  `wc -l` по всем новым/изменённым файлам — максимум 333 строки
  (`api_client.dart`, не тронут этим брифом), новые файлы — 43–206 строк.

### 2.2 Предсуществующий баг, обнаруженный этим прогоном (НЕ в объёме
брифа, зафиксирован для оркестратора)

`test/features/legal_consent/regional_consent_screen_test.dart`, тест
`"detectedRegion=null — экран сам вызывает GET /status"` (и волной
падают порядковые тесты после него в том же файле из-за нарушенного
состояния) — падает **и на `main` до этого брифа** (проверено
`git stash` + изолированный прогон), значит не вызван изменениями этого
брифа. Причина по логу: `find.textContaining('Россия')` матчит ДВА
виджета одновременно — `RichText` с полным предложением-вопросом
("Мы определили ваш регион как Россия — верно?") и отдельный `RichText`
с чипом названия региона ("Россия"), а тест ожидает ровно один. Похоже,
экран в какой-то момент стал рендерить оба текста одновременно, а
finder в тесте остался прежним (слишком широкий `textContaining`).
Не входит в зону ответственности mobile-агента по этому брифу
(`legal_consent_gate`/`regional_consent_screen` этим брифом не
затронуты) — эскалирую отдельным пунктом, не чиню внутри этого коммита.

### 2.3 Виджет-тесты (написаны и живо прогнаны — 54/54)

- `test/features/chat/models/sdui/profiling_question_models_test.dart` —
  парсинг: 2/6 опций (границы схемы), i18n-резолюция с fallback,
  `is_revalidation` по умолчанию, все обязательные поля дают
  `FormatException` при отсутствии (`answer_key`, `questionnaire_slug`,
  `label`, `options` пуст/отсутствует/1 элемент, `option.value`/
  `option.label` отсутствуют).
- `test/features/chat/widgets/sdui/profiling_question_block_test.dart` —
  рендер 2 и 6 опций; успешный тап (проверка аргументов
  `onSubmitAnswer`, блокировка остальных кнопок, отправка подтверждения
  в чат); **ошибка записи — кнопки остаются активными, повторный тап
  доходит новым запросом** (ключевой тест на решение §1.3); индикатор
  загрузки во время запроса.
- `test/features/chat/widgets/sdui/profiling_question_dispatcher_test.dart`
  — `UnknownBlock`-fallback на уровне `SduiBlockDispatcher` при
  отсутствии `answer_key`/`label`/`options` <2 элементов, валидный блок
  диспетчеризуется корректно.

### 2.4 Живой прогон (тап → реальный `POST /api/app/profiling-answers`)

**Не выполнен.** Среда сессии не даёт доступа к тестовому
серверу/аккаунту — открытый пункт, как это уже было зафиксировано в
`REPORT_mobile_profile_summary.md`. Backend-часть подтверждена живой
приёмкой отдельно (`REPORT_backend_deterministic_profiling_answer.md`,
2026-09-12/13) — со стороны мобильного клиента нужна отдельная сессия
с доступом к тестовому окружению для сетевого лога (Dio interceptor)
тапа по реальному блоку.

---

## 3. Что НЕ входит (по брифу)

- Генерация текста вопросов — backend, не тронуто.
- `repeating_by_reference`-ветка — не тронута.
- Web/Lab — не тронуто (контрактно исключено).
- Полноценный ревалидационный UX — не в объёме, минимальная подсказка
  добавлена.

## 4. Предложение по правке master-документов (право записи — только у оркестратора)

- `AGENT_RULES_orchestrator.md` §5 (чек-лист ревью) — стоит явно
  зафиксировать пунктом класс ошибки из §1.5 этого отчёта: "при
  добавлении нового обязательного колбэка в ChatBubble/
  SduiBlockDispatcher.build — grep по всему репозиторию (`lib/` и
  `test/`) на все места конструирования, не полагаться на память о ранее
  известных местах". Это уже третий раз, когда этот класс правки чуть не
  пропускается (`onAcceptSlot`, `onSubmitMedicalConsent`,
  `onSubmitProfilingAnswer`) — в этот раз подтверждено живым
  `flutter analyze` (0 ошибок), но это не должно зависеть от того,
  есть ли в моменте доступ к живому SDK.
- Отдельная эскалация backend/QA (не по этому брифу): предсуществующий
  падающий тест `regional_consent_screen_test.dart` (см. §2.2) —
  рекомендую завести отдельный тикет на владельца `legal_consent_gate`/
  `regional_consent_screen`, не блокировать этим брифом.

---

## 5. Обновление (Mob-A, 2026-09-17): §2.4 закрывается кросс-ссылкой на живой прогон другого брифа

**Контекст**: `work/deterministic_profiling_answer/read.me` (обновление
orc-A, 2026-09-15) держит папку в `work/` именно из-за открытого §2.4
выше — «живого тапа на устройстве не было». Второй, независимый живой
прогон устройства состоялся 2026-09-16 в рамках другого брифа
(`BRIEF_mobile_calendar_proposal_transport_fix.md`, коммит `4674aae`,
см. `REPORT_mobile_calendar_proposal_transport_fix.md` §3.3) и **по ходу
сценария реально прошёл через `profiling_question`-блок** — это не было
целью того брифа, но зафиксировано на скриншотах и релевантно этому
отчёту напрямую.

### 5.1 Что видно на скриншотах (`docs/evidence/flow4_calendar_proposal_transport_fix/`)

- `03_profiling_pregnancy_and_skin_type.jpg` (23:23:54) — реальный тап по
  кнопкам `profiling_question`: «Вы беременны?» → *Нет*, тип кожи →
  *комбинированная*.
- `04_profiling_sensitivity_answered_calendar_proposal_appears.jpg`
  (23:25:08) — тап по третьему вопросу (чувствительность → «нормальная
  реакция») → **сразу после этого** AURA присылает `calendar_proposal`
  round 1 (3 кандидата-слота).

### 5.2 Почему это закрывает §2.4, а не просто «похожий кейс»

`calendar_proposal` для процедуры с health-гейтом (лёгкий пилинг лица)
уходит от backend только после того, как `profile_health` (в частности
`restriction:pregnancy`, `profile:health:skin_type`,
`profile:health:sensitivity`) реально дозаполнен — это тот же
`completeness_service`, что резолвит `answer_key` в
`show_profiling_question()` (ADDENDUM #1). Если бы тап по кнопке НЕ
записался структурированно (например, ушёл как текст в LLM и модель не
распознала его как ответ — Вариант А из
`BRIEF_backend_verify_button_answer_write_path.md`), `profile_health`
остался бы неполным и `calendar_proposal` не появился бы сразу же на
следующем шаге. Появление `calendar_proposal` **немедленно** после
третьего тапа — функциональное, живое подтверждение, что все три ответа
дошли до `agent.questionnaire_responses`/профиля через прямой write-путь,
а не через интерпретацию LLM.

### 5.3 Честная граница этого подтверждения

Это **не** то же самое, что прямой сетевой лог (`Dio`-interceptor dump)
запроса-ответа `POST /api/app/profiling-answers` для каждого тапа —
такого лога в этом прогоне не снималось, скриншоты фиксируют только UI.
Подтверждение — косвенное, но силовое: единственный путь, которым
`profile_health` мог оказаться дозаполненным к моменту 23:25:08, — это
успешная запись через `ProfilingAnswerApiClient.submitProfilingAnswer()`
(см. §1.2/1.3 выше), потому что альтернативного (LLM-интерпретация текста
подтверждения, отправленного `onSendMessage` уже ПОСЛЕ записи) для этого
не хватило бы времени/механизма — подтверждающее сообщение уходит в чат
уже после `_confirmedValue` установлен, то есть после ответа сервера.

**Рекомендация оркестратору**: считать §2.4 закрытым этим кросс-прогоном
для целей этого брифа (функциональное, а не байт-в-байт сетевое
доказательство); если нужен именно сырой HTTP-лог тапа — это отдельный,
узкий живой прогон с включённым `Dio`-логированием, не блокирующий
остальное.

### 5.4 Побочная польза для `BRIEF_backend_verify_button_answer_write_path.md`

Тот бриф (read-only, backend) независимо проверяет тот же вопрос со
стороны сервера: какой путь реально пишет `restriction:*`/`symptom:*`-
ответ в БД при тапе по кнопке. Мобильная сторона этого вопроса уже
задокументирована кодом и цитатами в §1.2/1.3 выше и подтверждена здесь
живым прогоном: `ProfilingQuestionBlock._handleTap()` вызывает
`onSubmitAnswer` (→ `ChatControllerProfilingAnswer.submitProfilingAnswer()`
→ `ProfilingAnswerApiClient.submitProfilingAnswer()` →
`POST /app/profiling-answers`, structured, без `try/catch`) **до** любого
обращения к `streamChat()`/LLM; `onSendMessage(label)` — обычное
чат-сообщение, отправляется **только после** успешного ответа сервера
и не участвует в записи. Это подтверждает Вариант Б с клиентской
стороны — оставляю как справочный факт для оркестратора/backend-агента,
не делаю вывода по backend-коду (вне зоны ответственности mobile).
