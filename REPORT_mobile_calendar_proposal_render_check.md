# REPORT_mobile_calendar_proposal_render_check.md

**По брифу:** `BRIEF_mobile_calendar_proposal_render_check.md` +
`ADDENDUM_mobile_calendar_proposal_render_check.md`
(`vb_docs/work/flow4_calendar_proposal_silent_nonrender/`)
**Дата:** 2026-09-16
**Исполнитель:** Mob-A
**Статус:** Диагноз найден и подтверждён статическим анализом реального
кода mobile (`beauty_mobile`) и backend (`VB-backend`, read-only). Фикс
**не реализован** — вне скоупа обоих брифов ("фикс не брифован, пока не
подтверждена конкретная причина" / "решение оркестратора по направлению
фикса ещё не принято"). Ниже — только находки + regression-тесты,
подтверждающие их механически, без изменений в `lib/`.

⚠ **Оговорка про среду выполнения**: в песочнице агента отсутствует
Flutter/Dart toolchain (тот же класс ограничения, что и в предыдущих
сессиях — см. `git log`, диагнозы profile 0%/pending и unsupported-block).
Все находки ниже подтверждены **чтением реального кода** (не по памяти) и
двумя новыми test-файлами, которые нужно прогнать `flutter test` локально
(PowerShell на машине Mobile) для финального ✅ перед закрытием задачи —
результат такого прогона в этом отчёте отсутствует, это открытый хвост.

---

## Итог одной строкой

Найден **независимый mobile-баг**, не альтернатива backend-багу
(«не та сессия»), а вторая, отдельная причина, которая гарантированно
привела бы к пустому экрану **даже если бы backend всё сделал правильно**:
`calendar_proposal` v2 (`candidates`/`round`/`round_cap`) в реальном
SSE-потоке `app_chat.py` **никогда не приходит внутри `{"blocks": [...]}`**
— backend сознательно (`_split_blocks()`, докстринг модуля, BRIEF §2.1)
отправляет его отдельным полем `{"calendar_proposal": {...}}`. Mobile же
трактует именно это поле как **старый, задокументированно устаревший**
одноразовый passthrough-канал (`_applyCalendarProposalSilently()` →
`ApiClient.applyCalendarProposal()`, ждёт ключ `events`, которого в v2-блоке
нет) — в результате корректно построенный `SduiBlockDispatcher` →
`CalendarProposalBlock` (round-индикатор, кнопки кандидатов, accept/reject)
**ни разу не вызывается для реального трафика**, независимо от того,
пустые кандидаты или нет, "та" сессия или "не та".

---

## П.1 — Обработка пустого списка слотов

`sdui_block_dispatcher.dart::_buildCalendarProposal()` (строки 126–136) уже
обрабатывает `data.candidates.isEmpty` явно — деградирует в `UnknownBlock`
с видимым фоллбэком (не тишина): `unknown_block.dart` рендерит бабл с
иконкой и текстом `l10n.sduiUnsupportedBlock` = *«Это сообщение содержит
блок, который приложение пока не поддерживает»* (l10n_ru.dart:86-87).

**Вывод:** технически НЕ "тишина" — что-то видимое появляется. Но это
**не** специализированное состояние "подходящих слотов нет" — пользователь
увидит фразу про неподдерживаемый блок, что само по себе вводит в
заблуждение (звучит как баг приложения, а не как "слотов нет"). Это
самостоятельный, отдельный от корневой причины ниже UX-gap — фиксирую как
находку по инструкции брифа ("зафиксировать это как отдельный gap
независимо от результата п.2"), в фикс не включаю (брифом не покрыто).

**На практике этот путь недостижим для реального трафика** — см. итог
одной строкой выше и П.5: backend никогда не кладёт `calendar_proposal`
(пустой или нет) в `blocks[]`, значит `_buildCalendarProposal()` в проде
не вызывается вовсе для этого типа блока.

---

## П.2 — Grep по всем местам построения `calendar_proposal`

```
grep -rn "calendar_proposal" lib/ test/
```

Полный вывод grep приложен ниже находкам. Ключевое: **дублирующийся
устаревший обработчик СУЩЕСТВУЕТ и АКТИВНО ВЫЗЫВАЕТСЯ**, а не тихо
перехватывает часть событий, как предполагал бриф — он перехватывает **все**
события `calendar_proposal`, приходящие с реального backend:

- `chat_controller.dart:219-222` — `handleStreamEvent()`:
  ```dart
  if (event.containsKey('calendar_proposal')) {
    _applyCalendarProposalSilently(
      Map<String, dynamic>.from(event['calendar_proposal'] as Map),
    );
  }
  ```
  Этот `if` идёт **первым** в цепочке, до ветки `blocks`.

- `chat_controller.dart:277-286` — сам метод:
  ```dart
  void _applyCalendarProposalSilently(Map<String, dynamic> proposal) {
    final events = (proposal['events'] as List<dynamic>? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (events.isEmpty) return;

    ApiClient.applyCalendarProposal(events: events)
      .then((_) => onCalendarApplied?.call(events.length))
      .ignore();  // ← подавляет и ошибку и предупреждение о типе
  }
  ```
  Комментарий в коде (добавлен коммитом `239a27f`, 2026-08-30, тот же
  коммит, что ввёл v2-виджет) утверждает: *"СТАРЫЙ, одноразовый
  passthrough-путь propose_calendar_plan... он НЕ связан с новым SDUI-блоком
  calendar_proposal v2, который приходит через {"blocks": [...]}"*.
  **Это утверждение проверено против реального backend-кода
  (`VB-backend/app/routers/app_chat.py`) и опровергнуто** — см. П.5. Оно
  было записано как допущение при написании v2-виджета и никогда не
  сверялось с транспортным слоем backend.

- `ApiClient.applyCalendarProposal()` (`lib/core/api/api_client.dart:197-205`)
  шлёт `POST /app/calendar/apply` с телом `{"events": [...]}`. Проверено
  по `VB-backend` (read-only): `grep -rn "calendar/apply" app/` →
  **0 результатов** — этого эндпоинта в текущем backend физически не
  существует. Даже в гипотетическом сценарии непустого `events` вызов ушёл
  бы в 404, ошибка которого намеренно подавлена `.ignore()`.

**Вывод:** мёртвый код не просто "оставлен" — он единственный обработчик на
пути реального SSE-поля `calendar_proposal`, построен под контракт, которого
больше нет ни на клиенте (ждёт `events`, а не `candidates`), ни на сервере
(эндпоинт `/app/calendar/apply` удалён). `CalendarProposalBlock`/
`SduiBlockDispatcher` при этом полностью корректны и покрыты тестами
(`test/features/chat/calendar_proposal_block_test.dart`, 9 тестов,
проверено чтением) — сами по себе не виноваты, просто до них ничего не
доходит с реального транспорта.

---

## П.3 — Дедупликация/сравнение блоков

```
grep -rn "dedup\|isDuplicate\|sameAs\|== previous\|lastBlock\|hashCode\|identical(" lib/features/chat/
```
→ **0 результатов** (не считая тестового шума).

Дополнительно проверено на уровне рендера — `chat_bubble.dart:177-208`:
```dart
final blocks = w.message.blocks;
...
if (!w.isStreamingPlaceholder && blocks != null && blocks.isNotEmpty)
  ...blocks.map((block) => SduiBlockDispatcher.build(block, ...)),
```
Каждое сообщение рендерит **свой собственный** `blocks`-список через
`.map()`, без сравнения с предыдущими сообщениями/блоками. Механизма
подавления "повторного" блока **не существует**.

**Вывод:** гипотеза 3 брифа (ошибочная дедупликация съедает повторные
блоки) **не подтверждена** — такого кода нет вообще, ни в контроллере,
ни в рендере.

---

## П.4 — Сверка с прецедентом 2026-08-08 (путаница кортежа `dispatch_tool()`)

Коммит `dc787ab` (2026-08-10 21:59:55 +0300, `fix(chat): handle blocks SSE
event in ChatController, fix copyWith to propagate blocks`) — ближайший по
времени к упомянутой дате, добавил обработку `{"blocks": [...]}` и вынес
`handleStreamEvent()` отдельным методом. **Фикс на месте, не откатывался**
последующими коммитами (`git log -p --follow` по `chat_controller.dart`
подтверждает непрерывное присутствие ветки `blocks` во всех последующих
версиях файла, включая текущую).

Важный нюанс: тот же коммит **сохранил** (не тронул) ветку
`if (event.containsKey('calendar_proposal'))` первой в цепочке — на тот
момент это было корректно (единственный существовавший контракт для этого
поля был старый passthrough). Проблема возникла позже, в `239a27f`
(2026-08-30), когда `calendar_proposal` v2 получил тот же ключ события, но
не был подключён к этой ветке, а описанный выше (П.2) недокументированный
допущением комментарий закрыл вопрос без сверки с backend.

**Вывод:** прецедент 2026-08-08 сам по себе не рецидивировал (фикс на
месте) — но именно расширение того же файла двумя неделями позже создало
структурно похожий класс проблемы (клиент неверно резолвит, откуда
приходят реальные данные конкретного tool-результата) на новом месте.

---

## П.5 — Отличие от `calendar_event_confirmation`

Подтверждено чтением `VB-backend/app/routers/app_chat.py:251-263`
(`_split_blocks()`, read-only, не мой репозиторий, но проверка обязательна
по AGENT_RULES §0):

```python
def _split_blocks(blocks: list[dict]) -> tuple[list[dict], Optional[dict]]:
    """calendar_proposal — отдельный result planning-кейс, не generic
    SDUI-блок..."""
    calendar_proposal = None
    other_blocks = []
    for block in blocks:
        if block.get("type") == "calendar_proposal" and calendar_proposal is None:
            calendar_proposal = block
        else:
            other_blocks.append(block)
    return other_blocks, calendar_proposal
```

и модульный докстринг файла (строки 12-17):
```
SSE-контракт расширен аддитивно (см. BRIEF §2.1):
    {content}(чанками) → {blocks}? → {calendar_proposal}? → {conversation_id} → [DONE]
calendar_proposal остаётся отдельным полем (result planning, не generic
SDUI-блок) — не сворачивается в blocks, см. BRIEF §2.1.
```

Это **сознательное, задокументированное backend-архитектурное решение**,
подтверждённое по факту схемой блока (`VB-backend/app/contracts/
sdui_blocks/calendar_proposal.schema.json`, содержит реальный v2-формат
`candidates`/`round`/`round_cap`) — то есть да, backend в реальности
кладёт в это отдельное поле именно v2-блок, не только старый `events`.

`calendar_event_confirmation` НЕ подпадает под условие
`type == "calendar_proposal"` в `_split_blocks()` → остаётся в
`other_blocks` → уходит клиенту через `{"blocks": [...]}` → корректно
доходит до `SduiBlockDispatcher` → рендерится. Это и есть буквальная,
единственная причина, почему в одной и той же тестовой сессии один блок
сработал, а другой — нет: **не разница в mobile-парсинге двух блоков, а
разница в SSE-канале доставки**, который mobile обрабатывает верно для
одного канала (`blocks`) и в корне неверно — для другого (`calendar_proposal`).

⚠ Важно: это делает п.5 брифа НЕ mobile-парсинговым отличием, а
транспортным. Совпадает с общим выводом отчёта — баг не в
`CalendarProposalBlock`/`SduiBlockDispatcher` (они не участвуют в
реальном пути вовсе), а в маршрутизации события в `ChatController`.

---

## Проверка 1 (аддендум) — сессия `241168f8` (18:00, "правильная")

Полный сырой JSON блока не был приложен backend-отчётом файлом (только
SQL-запросы + табличное summary, Дампы 3-4) — реконструирована фикстура по
задокументированным агрегированным полям (`scheduling_session_id`, `round`,
`round_cap`, час, дни недели — дословно из отчёта); `slot_id`/`start`/`end`
достроены структурно по образцу уже давно сверенной с живым payload
`calendar_proposal.mock.json` (см. `_readme` нового файла фикстур). Это
честная оговорка — не выдаю за byte-exact дамп.

Новый файл `test/fixtures/calendar_proposal_live_trace_2026_09_14.mock.json`
+ `test/features/chat/calendar_proposal_channel_routing_test.dart`:

- **Контрольный тест** (`SduiBlockDispatcher.build()` напрямую, тем же
  методом, что уже использует `calendar_proposal_block_test.dart`):
  блок с `scheduling_session_id=241168f8-...`, `round=1/3`, кандидаты
  Пн/Вт/Ср 18:00 — рендерится корректно (`Попытка 1 из 3` +
  3 кнопки `Понедельник/Вторник/Среда, 18:00`), если доставлен туда, куда
  реально доставляется `calendar_event_confirmation`.
- **Репродукция бага** (`ChatController.handleStreamEvent()`, тот путь,
  которым это реально приходит от backend — `{"calendar_proposal": {...}}`):
  `messages.last.blocks` остаётся `null` — ничего не добавляется в
  сообщение, экран остаётся пустым **для единственного блока во всём
  трейсе, где backend сделал абсолютно всё правильно**.

**Ответ на вопрос Проверки 1:** блок НЕ рендерится в реальном приложении —
не из-за содержимого (оно корректно), а из-за канала доставки.

## Проверка 2 (аддендум) — сессии `c6dfcc17`/`16a2abbc` (15:00, "чужие")

Аналогично: фикстура `check2_session_c6dfcc17_wrong_but_nonempty_15h`
(`round=3/3`, кандидаты Пн/Вт/Ср 15:00, та же реконструкция по summary
backend-отчёта, честно помечена). Тот же тест-файл:

- Контрольный виджет-тест — рендерится корректно (`Попытка 3 из 3` +
  3 кнопки 15:00).
- Репродукция через `handleStreamEvent({'calendar_proposal': {...}})` —
  `messages.last.blocks` снова `null`.

**Ответ на вопрос Проверки 2 (ключевой для аддендума):** блоки с
"чужим", но валидным непустым `candidates` **тоже не рендерятся вообще**
— экран пустой независимо от корректности содержимого. Это подтверждает
формулировку аддендума: **backend-баг (не та сессия) НЕ является полным
объяснением жалобы** — вторая, независимая mobile-причина существует и
сама по себе достаточна, чтобы объяснить "ничего не появилось" даже если
бы backend ни разу не ошибся с выбором сессии.

---

## Открытые хвосты

1. **Реальный прогон `flutter test` не выполнен в этой сессии** (нет
   toolchain в песочнице) — оба новых теста
   (`calendar_proposal_channel_routing_test.dart`) написаны и статически
   проверены (баланс скобок, валидность JSON-фикстуры, сверка сигнатур с
   реальными `ChatController`/`ChatMessage`/`SduiBlockDispatcher`), но
   нужен живой прогон на машине Mobile (PowerShell) для окончательного ✅
   перед закрытием mobile-части.
2. **Фикстуры Проверок 1/2 — реконструкция, не byte-exact дамп.** Если
   для окончательного закрытия задачи нужна дословная сверка (как это
   было сделано для `with_candidates`/`round_2_of_3` в исходном
   `calendar_proposal.mock.json` против `REPORT_backend_flow4_mobile_
   verification_response.md`) — нужен файл с реальным JSON от
   backend-агента/оркестратора по `message.id=14e50bfa-...` и по одному из
   пяти сообщений с `c6dfcc17`/`16a2abbc`, не таблица в markdown.
3. **Направление фикса (вне скоупа этого брифа, для следующего)**:
   `ChatController.handleStreamEvent()` должен трактовать SSE-поле
   `calendar_proposal` так же, как `blocks` — прогонять через
   `SduiBlockDispatcher` (тело поля уже структурно совместимо с
   `CalendarProposalBlockData.fromJson()`, что и показывает "контрольный"
   тест выше), а не через `_applyCalendarProposalSilently()`. Сам
   `_applyCalendarProposalSilently()`/`ApiClient.applyCalendarProposal()`
   — код, ссылающийся на несуществующий backend-эндпоинт
   (`POST /app/calendar/apply`, подтверждено grep по `VB-backend`) —
   кандидат на полное удаление, не просто на обход. Решение по объёму и
   моменту фикса — за оркестратором (не беру на себя, брифом не покрыто).
4. **П.1-находка (нет состояния "слотов нет")** остаётся отдельным,
   самостоятельным gap (по инструкции брифа) — сейчас непрактична (путь
   недостижим для реального трафика), но станет актуальной, как только
   транспортный баг будет исправлен и `calendar_proposal` с пустыми
   `candidates` реально сможет дойти до `SduiBlockDispatcher`.
5. **Схема контракта** (`contracts/sdui_blocks/calendar_proposal.schema.json`
   в `vb_docs`) по-прежнему физически отсутствует в `vb_docs`
   (read.me задачи утверждает "РАЗРЕШЕНО 2026-09-15" в `flow4_scheduling_v1`
   — не проверял отдельно, вне скоупа этого брифа; в `VB-backend`
   аналогичный файл **есть** и совпадает с моделью 1:1).

---

## Приложение — полный вывод grep (п.2)

```
lib/features/chat/models/chat_message.dart:9
lib/features/chat/models/sdui/legal_consent_gate_models.dart:5
lib/features/chat/models/sdui/calendar_proposal_models.dart:1,5
lib/features/chat/models/sdui/calendar_event_confirmation_models.dart:9,17
lib/features/chat/chat_controller.dart:206,207,211,214,219,221
lib/features/chat/widgets/sdui/sdui_block_dispatcher.dart:3,8,16,22,71,123,135,143,144,151
lib/features/chat/widgets/sdui/legal_consent_gate_block.dart:12
lib/features/chat/widgets/sdui/calendar_proposal_block.dart:4,6
lib/core/l10n/l10n_ru.dart:104
lib/core/l10n/l10n_en.dart:101
lib/core/l10n/app_localizations.dart:82
test/fixtures/calendar_event_confirmation.mock.json:2
test/fixtures/calendar_proposal.mock.json:2,4,33,61,78,88,105
test/features/chat/calendar_event_confirmation_block_test.dart:22
test/features/chat/questionnaire_prompt_block_test.dart:96,100,103
test/features/chat/calendar_proposal_block_test.dart:10,13,29,52,75,91,120,143,174,191,208,225
test/features/chat/widgets/sdui/profiling_question_block_test.dart:150
```
Ни одного результата вне `lib/features/chat/` и `test/` — второго,
независимого от `chat_controller.dart`/`sdui_block_dispatcher.dart` места
построения блока не найдено.
