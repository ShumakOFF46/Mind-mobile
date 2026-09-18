# REPORT: Mobile — Profile Summary v1 (рендер)

Бриф: `BRIEF_mobile_profile_summary.md`. Контракт: `CONTRACT_profile_summary_v1.md`.
Статус: код готов, часть чек-листа приёмки НЕ закрыта агентом (см. «Открыто» ниже) — среда сессии не давала Flutter-тулчейна и живого бэкенд-аккаунта.

---

## Что сделано

**Изменённые файлы:**
- `lib/core/api/api_client.dart` — новый метод `getProfileSummary()`
  (`GET /app/profile-summary`, обычный `dio.get()`, не SSE — read-путь).
- `lib/core/l10n/app_localizations.dart`, `l10n_en.dart`, `l10n_ru.dart` —
  два новых ключа: `profileSummaryTitle`, `profileSummaryPending`.
  `l10n_kk.dart` не трогался — наследует `L10nEn`.
- `lib/features/profile/profile_screen.dart` — подключение
  `_loadSummary()` (в `initState()` и в `RefreshIndicator.onRefresh`),
  рендер `ProfileSummaryCard` между `ProfileHeader` и `ProfileTabs`.

**Новые файлы:**
- `lib/features/profile/models/profile_summary.dart` — `ProfileSummary`
  + `ProfileSummaryStatus`, `fromJson()`, `hasDisplayableText`.
- `lib/features/profile/widgets/profile_summary_card.dart` — карточка,
  3 состояния по `summary.status`, pulse-skeleton без внешней
  shimmer-зависимости.
- `test/features/profile/models/profile_summary_test.dart` — 5 юнит-тестов
  парсинга (`ready`/`pending`/`failed`-с-текстом/неизвестный статус/
  отсутствующий `completion_percent`).
- `test/features/profile/widgets/profile_summary_card_test.dart` —
  5 виджет-тестов на три визуальных состояния карточки.

Все изменённые/новые файлы — в пределах лимита 300–400 строк (макс. —
`api_client.dart`, 333 строки).

---

## Находка при интеграции — эскалирую, не решаю тихо

`profile_screen.dart` до этой правки дополнительно дёргал
`GET /app/profile/status` и показывал его поле `completion` в
`ProfileHeader`. Новый эндпоинт даёт свой `completion_percent` —
детерминированный агрегат по тем же 7 `profile_*` секциям
(`compute_aggregate_completeness()`, контракт §5). Показывать на одном
экране два потенциально РАЗНЫХ процента заполнения одного и того же
профиля — очевидный UX-баг, поэтому:

- вызов `GET /app/profile/status` из `_loadProfile()` удалён;
- `ProfileHeader` переведён на `completion_percent` из нового контракта
  как более новый и явно детерминированный источник.

**Не проверено мной**: совпадает ли `/app/profile/status.completion` по
смыслу с `completion_percent`, и нет ли у первого эндпоинта других
полей/потребителей помимо `completion` (например, других экранов, не
входивших в переданные мне файлы). Решение задокументировано прямо в
коде (`profile_screen.dart`, комментарий над `_loadSummary()`). Прошу
оркестратора подтвердить или поправить.

---

## Открыто — НЕ закрыто в этой сессии (чек-лист брифа)

Причина одна и та же по всем пунктам: в среде сессии нет Flutter SDK
(сеть ограничена доменами пакетных реестров, `storage.googleapis.com` и
инфраструктура Flutter недоступны) и нет живого тестового аккаунта/
бэкенда для ручного прогона.

- [ ] Живой `GET /api/app/profile-summary` через реальный dio-клиент на
      тестовом аккаунте — НЕ выполнено, только код-ревью.
- [ ] Визуальная проверка `ready`-состояния на реальном ответе backend —
      НЕ выполнено.
- [ ] `flutter test` — числа до/после — НЕ выполнено, тесты написаны, но
      не запускались. Ручная сверка: баланс скобок по всем правленным
      файлам сошёлся, grep на мёртвые ссылки (`_status`,
      `/app/profile/status`) — чисто.
- [x] Прогресс-бар 0%/100% — граничные случаи покрыты юнит-тестом модели
      (`completion_percent` отсутствует → 0; контракт гарантирует, что
      поле всегда присутствует в реальном ответе).
- [x] `failed` с непустым `text` визуально не отличается от `ready` —
      покрыто виджет-тестом (нет `Icons.error_outline`/
      `Icons.warning_amber_rounded` в дереве).
- [x] Refetch на фокус экрана — реализован через существующий паттерн
      файла (плоский top-level `GoRoute`, `initState()` пересоздаётся
      при каждом заходе на `/profile`, тот же принцип, что `autoDispose`
      у `calendar_screen.dart`) + повторный вызов в `RefreshIndicator`.

**Требуется от Mobile до мержа**: реальный прогон `flutter test` и живой
smoke-тест на тестовом аккаунте — я не могу это подтвердить из текущей
среды.

---

## Отдельно, не по этому брифу — статус критичной находки от 2026-09-09

Использованные в этой сессии GitHub PAT-токены — те же, что аудит
`REPORT_backend_repo_docs_audit_20260909.md` пометил как закоммиченные в
открытом виде в `VB-backend`. Ротация токенов на момент этой сессии,
насколько мне видно из `vb_docs`, ещё не отражена как выполненная —
повторяю рекомендацию аудита: ротация + вычистка git-истории, до того
как эти токены будут использоваться дальше.
