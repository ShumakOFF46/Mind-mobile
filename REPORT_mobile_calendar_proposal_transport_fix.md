# REPORT_mobile_calendar_proposal_transport_fix.md

**По брифу:** `BRIEF_mobile_calendar_proposal_transport_fix.md`
(`vb_docs/work/flow4_calendar_proposal_silent_nonrender/`)
**Дата:** 2026-09-16
**Исполнитель:** Mob-A
**Коммит:** `35ab43f` → `642efd4` → `4674aae` (`beauty_mobile`, ветка `main`)
**Статус:** ВСЕ пункты брифа (П.1, П.2, П.3.1, П.3.2, П.3.3) закрыты живыми
доказательствами. Готово к финальному ревью оркестратора.

---

## П.1 — Фикс маршрутизации

`lib/features/chat/chat_controller.dart::handleStreamEvent()`:

- Событие `calendar_proposal` теперь уходит в тот же путь, что и `blocks[]`
  — общий приватный метод `_appendBlocksToLastMessage()`, который **мёрджит**
  блок в `message.blocks` (а не перезаписывает — важно, если оба поля
  когда-нибудь придут на одно сообщение). Итоговый рендер идёт через уже
  существующий `SduiBlockDispatcher`/`CalendarProposalBlock`, ничего нового
  там писать не пришлось — контрактный ключ `version` и парсинг
  `CalendarProposalBlockData.fromJson()` уже были корректны (см. отчёт по
  диагностике).
- Полностью удалены, не обойдены:
  - `ChatController._applyCalendarProposalSilently()`
  - `ChatController.onCalendarApplied`
  - `ApiClient.applyCalendarProposal()` (`POST /app/calendar/apply`)
  - Проверено: `grep -rn "calendar/apply\|applyCalendarProposal" lib/` →
    **0 результатов** (ровно критерий брифа).
- **Побочный эффект, зафиксирован честно, не скрыт**: `onCalendarApplied`
  был единственным местом во всём приложении, вызывающим
  `ref.invalidate(calendarBadgeProvider)` (обновление бейджа календаря в
  AppBar чата) и показывающим снэкбар "N процедур добавлено". Убрал вызов
  из `chat_screen.dart` вместе с удалённым колбэком, поправил комментарии
  в `calendar_badge_provider.dart`. **На практике это не новая регрессия**
  — этот путь и раньше не срабатывал в реальном трафике (payload старого
  флоу `events` никогда не совпадал с тем, что шлёт текущий backend,
  который шлёт `candidates`). Но это открытый gap: у нового negotiation
  loop (`acceptSchedulingSlot()`) нет своего триггера инвалидации бейджа.
  Не чинил — вне скоупа этого брифа (только маршрутизация + no-slots
  состояние), эскалирую отдельной строкой ниже.
- Regression: `calendar_event_confirmation` (канал `blocks[]`) не менялся
  по логике — только сам механизм записи в `message.blocks` теперь мёрджит
  вместо перезаписи, что для одиночного события эквивалентно прежнему
  поведению. Подтверждено тестом (см. П.3.1 ниже).

## П.2 — Состояние «подходящих слотов нет»

- Новый виджет `CalendarProposalEmptyBlock`
  (`lib/features/chat/widgets/sdui/calendar_proposal_block.dart`) — та же
  визуальная база (`aiBubble`, скруглённый контейнер), что и у
  `CalendarProposalBlock`, но без интерактивных элементов: иконка
  `Icons.event_busy` + текст.
- Подключён в `sdui_block_dispatcher.dart::_buildCalendarProposal()` вместо
  `UnknownBlock` для случая `data.candidates.isEmpty`.
- Текст — **плейсхолдер**, как и требовал бриф: новый l10n-ключ
  `schedulingNoSlotsFound` добавлен в `app_localizations.dart` (абстрактный
  геттер), `l10n_ru.dart` ("Подходящих слотов не найдено.") и `l10n_en.dart`
  ("No suitable slots were found."), обе реализации помечены
  `// TODO: copy review`. `l10n_kk.dart` (казахский, наследует `L10nEn`)
  автоматически получил английский текст через наследование — отдельно
  переопределять не пришлось, ничего не сломалось (казахская локаль и
  раньше не имела собственного перевода для большинства строк, это
  задокументированный паттерн файла).

## П.3 — Живое подтверждение

Все три подпункта закрыты живыми данными от Mobile — тесты (3.1),
byte-exact фикстуры (3.2) и реальное устройство с реальным backend (3.3):

### 3.1 — Тесты: реальный прогон получен от Mobile (2026-09-16)

```
PS C:\GitHub\beauty_mobile> flutter test
...
00:37 +143 -1: Some tests failed.
```

**143 запущено, 142 прошло, 1 упал.** Упавший тест —
`test/features/legal_consent/regional_consent_screen_test.dart:
"detectedRegion=null — экран сам вызывает GET /status"` — это **тот же
самый, уже задокументированный предсуществующий баг**
(`REPORT_mobile_deterministic_profiling_answer.md` §2.2, подтверждено там
`git stash` на `main` ДО того брифа — падает независимо от него).
Причина не изменилась: `find.textContaining('Россия')` матчит два виджета
одновременно (вопрос-предложение + отдельный чип названия региона).
**Не связан с этим брифом**, не блокирует закрытие П.3.1.

Арифметика подтверждает отсутствие регрессий и явно показывает, что
новые тесты реально выполнились: предыдущий полный прогон проекта
(тот же бриф deterministic_profiling_answer, до всех правок этой задачи)
дал **136** тестов. `calendar_proposal_channel_routing_test.dart` в
текущей версии содержит ровно **7** тестов (3 widget + 4 ChatController).
`136 + 7 = 143` — совпадает с фактическим итогом день-в-день, то есть все
7 новых/переписанных тестов реально были собраны и выполнены (не
пропущены сборкой), и среди 142 прошедших нет ни одного из тех 7 с
провалом (единственный `-1` — старый известный файл, не мой).

**П.3.1 закрыт.** Живые числа — не «должно проходить», а факт: 142/143 в
норме, 1/143 — известный, неродственный, задокументированный ранее баг.

### 3.2 — Байт-точные фикстуры

**Заменены на byte-exact (2026-09-16, после доставки backend'ом).** Ранее
реконструированная `test/fixtures/calendar_proposal_live_trace_2026_09_14.mock.json`
**удалена**, вместо неё:

- `test/fixtures/calendar_proposal_live_241168f8.wire.json` — дословная
  копия `calendar_proposal_message_14e50bfa_session_241168f8.wire.json`
  из `vb_docs` (round 1/3, session `241168f8`, слоты 18:00 Пн/Вт/Ср,
  21–23 сентября 2026).
- `test/fixtures/calendar_proposal_live_c6dfcc17.wire.json` — дословная
  копия `calendar_proposal_message_2f61e65b_session_c6dfcc17.wire.json`
  (round 3/3, session `c6dfcc17`, слоты 15:00, те же три дня).

Оба файла скопированы **как есть**, без добавления `_readme`/комментариев
внутрь JSON (это сломало бы byte-exactness) — происхождение и контекст
задокументированы в шапке `calendar_proposal_channel_routing_test.dart`.
Взят именно `.wire.json`-вариант (compact, как реально идёт по SSE), а не
pretty-`.json` — по прямому указанию `ADDENDUM_mobile_calendar_proposal_
transport_fix.md`, "Аддендум 2".

**Независимо перепроверено** (не только со слов backend/оркестратора):
`json.load()` для каждой пары `pretty.json`/`.wire.json` из `vb_docs` даёт
Python-объекты, равные друг другу (`p == w` → `True` для обеих пар) —
подтверждает claim "byte-exact" технически, не только по документации.

`calendar_proposal_channel_routing_test.dart` переписан под новые
фикстуры: `ChatController`-тесты теперь скармливают файл целиком (он уже
в форме `{"calendar_proposal": {...}}` — ровно SSE-событие), widget-тесты
берут вложенный объект. Тексты кандидатов/round-индикатора не изменились
относительно прежней реконструкции (даты 21–23 сентября вместо
угаданных 14–16 — единственная содержательная разница), поэтому
ассерты те же.

### 3.3 — Эмулятор/устройство со скриншотом/видео — ЗАКРЫТ (2026-09-16)

Живой прогон сделан Mobile на реальном устройстве, с реальным backend, на
коммите около `4674aae`. Скриншоты и разбор — `docs/evidence/
flow4_calendar_proposal_transport_fix/` (7 файлов + `README.md` с
хронологией и таймстемпами).

**Сценарий** (пользователь Олег): *«привет, хочу записаться на легкий
пилинг лица, предпочтительно вечером по будням»* → `legal_consent_gate`
(согласие на данные о здоровье) → `profiling_question` (беременность:
нет; тип кожи: комбинированная; чувствительность: нормальная реакция) →
**AURA присылает `calendar_proposal` round 1** — на экране появляется
«Попытка 1 из 3» + 3 кликабельные кнопки-кандидата (Четверг/Пятница/
Понедельник, 18:00) + «Ни одно не подходит». **Это решающее
доказательство**: до фикса на этом месте была тишина (см.
`REPORT_mobile_calendar_proposal_render_check.md`) — теперь блок реально
рендерится на живом трафике.

Пользователь принял один из кандидатов → «Запись подтверждена.» → в
экране календаря появилась запись `home_peeling_light`, 25 сентября,
18:00, 20 мин. **Независимо перепроверено**: 25 сентября 2026 —
действительно пятница (`datetime.date(2026,9,25).strftime('%A')` →
`Friday`), совпадает с принятым кандидатом «Пятница, 18:00»; длительность
20 мин совпадает с `end - start` в byte-exact фикстуре round 1 сессии
`241168f8` (18:00–18:20) — то есть это не просто "какой-то" рендер, а
структурно тот же контракт, что и в живом трейсе исходной жалобы.

Раунд 2/3 (кнопка «Ни одно не подходит») и специализированное состояние
«слотов нет» (П.2) в этом конкретном прогоне не встретились — не
проверены живьём в этой сессии (не блокирует закрытие, оба уже покрыты
`calendar_proposal_channel_routing_test.dart`/`calendar_proposal_block_test.dart`
на уровне тестов). Полный список — в `README.md` папки evidence.

**П.3.3 закрыт.** Бриф закрыт полностью.

### 3.4 — Продуктовый вопрос из аддендума (health-гейт vs "слотов нет")

`ADDENDUM_mobile_calendar_proposal_transport_fix.md` указывает: пустой
`candidates` может означать не только "нет свободного времени", но и
срабатывание health-гейта (`contraindication_checks`, в частности
`restriction:pregnancy`) для пользователя с незаполненной
`profile_health`-анкетой — backend на 2026-09-16 не различает эти два
случая машиночитаемо в самом блоке. Текст `CalendarProposalEmptyBlock`
("Подходящих слотов не найдено") в этом случае будет вводить в
заблуждение.

**Фиксирую как осознанный, а не случайный компромисс** (аддендум явно
просит не молчать об этом): плейсхолдер остаётся универсальным на первую
итерацию, `// TODO: copy review` в `l10n_ru.dart`/`l10n_en.dart` уже
покрывает и этот случай, отдельно ничего не менял — нового кода до
продуктового решения не требуется (аддендум это прямо оговаривает).
Решение — за постановщиком задачи, не мой фикс.

---

## Escalation (не в фиксе, для отдельного рассмотрения)

`ref.invalidate(calendarBadgeProvider)` теперь нигде не вызывается во всём
приложении — единственный существовавший триггер был завязан на удалённый
мёртвый код. Новый negotiation loop (`ChatController.acceptSchedulingSlot()`)
не инвалидирует бейдж календаря после подтверждённой записи. Как отмечено
выше, это не новая регрессия (путь и раньше не срабатывал в реальном
трафике), но теперь это явный, осознанный gap, а не случайный. Решение —
добавлять ли `ref.invalidate(calendarBadgeProvider)` в
`acceptSchedulingSlot()`/на уровне виджета, вызывающего его — вне скоупа
`BRIEF_mobile_calendar_proposal_transport_fix.md`, нужен отдельный бриф или
явное решение оркестратора.

---

## Файлы, изменённые (коммиты `35ab43f` + `642efd4` + evidence)

```
lib/core/api/api_client.dart                                  (-10)
lib/core/l10n/app_localizations.dart                           (+6)
lib/core/l10n/l10n_en.dart                                     (+3)
lib/core/l10n/l10n_ru.dart                                     (+3)
lib/features/calendar/providers/calendar_badge_provider.dart  (+16/-6)
lib/features/chat/chat_controller.dart                        (+45/-30)
lib/features/chat/chat_screen.dart                             (+12/-12)
lib/features/chat/widgets/sdui/calendar_proposal_block.dart    (+39)
lib/features/chat/widgets/sdui/sdui_block_dispatcher.dart       (+7/-4)
test/features/chat/calendar_proposal_channel_routing_test.dart (переписан дважды)
test/fixtures/calendar_proposal_live_trace_2026_09_14.mock.json (удалён)
test/fixtures/calendar_proposal_live_241168f8.wire.json         (новый, byte-exact)
test/fixtures/calendar_proposal_live_c6dfcc17.wire.json         (новый, byte-exact)
docs/evidence/flow4_calendar_proposal_transport_fix/            (новый, 7 скриншотов + README.md)
```
