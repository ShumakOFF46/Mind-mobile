# BUGREPORT: Profile 0%/pending + calendar procedure_not_found — оба НЕ мобильные

Источник: скриншот `МОЙ ПРОФИЛЬ` (0%, "AURA ещё формирует описание") + лог
чат-трейса (tool call `propose_calendar_plan` → `procedure_not_found`),
приложенные Mobile 2026-09-10. Диагностировано по живому коду `VB-backend`
(read-only), не по догадке.

---

## 1. Profile Summary 0% / pending, хотя диалог был

**Не баг Profile Summary v1 (мобильная реализация из `54bb0fb`).**
`completion_percent` считается `CompletenessService.compute_aggregate_completeness()`
(`app/services/questionnaire/completeness_service.py`) строго из
структурированных `questionnaire_responses.answers`, ключи `profile_*`.
Диалог в трейсе — целиком свободный текст ("скорее жирная", "мою по утрам
с мылом"), обрабатываемый через
`app/services/questionnaire/extraction_service.py::extract_answer_from_text`,
который на данный момент — **Phase 1 заглушка**, всегда возвращающая
`{"value": None, "certainty": "not_mentioned"}` (докстринг файла явно это
фиксирует, TODO(Phase 2) Шаг 7 не реализован, то же подтверждено
комментарием в `profile_summary_service.py::is_usable_answer`).

Следствие: для ЛЮБОГО пользователя, который общался только текстом (не
через `input_mode: buttons` questionnaire_prompt), `total_answered = 0` →
`completion_percent = 0`, `summary.status = pending` — это ожидаемое
поведение текущей (Phase 1) реализации extraction, не регрессия.

Подтверждение, что мобильный клиент отрисовал именно честный ответ
сервера, а не проглотил ошибку сети: `ProfileSummaryCard` показывает
italic-плейсхолдер ВМЕСТЕ со skeleton только при `summary != null`
(успешный парсинг ответа); при сетевой ошибке `_loadSummary()` оставляет
`_summary == null`, и рендерится голый skeleton без текста. На
скриншоте есть оба элемента → запрос прошёл, бэкенд ответил `0%`/`pending`
по факту данных.

**Не мой скоуп (Mobile) — нужен отдельный бриф**: либо реализовать
Phase 2 Шаг 7 (`extraction_service.py`, реальный LLM-вызов с полем
`certainty`), либо — если это осознанно отложено — явно развести в UX
"заполнено через диалог, но не через анкету" от "профиль реально пуст",
чтобы 0% не выглядел как баг для пользователей, которые активно
общались с AURA.

---

## 2. `propose_calendar_plan` → `procedure_not_found`

`procedure_slug: "morning_skin_care_routine"` не найден в каталоге
процедур — не нашёл такого slug ни в сидах, ни в content_catalog
(`app/services/content_catalog/`). Похоже на галлюцинацию модели при
tool-calling: slug не заземлён на реальный enum каталога. Тоже не
мобильное — мобильный клиент только рендерит финальный SSE-ответ ассистента
(это отработало верно — пользователь увидел вежливое "Ой, извини...").
Нужен бэкенд/prompt-engineering фикс: либо передавать модели актуальный
список валидных `procedure_slug` в контексте инструмента, либо
валидировать/маппить slug до вызова оркестратора расписания.

---

## Резюме для оркестратора

Обе находки — не про мобильный код, изменений в `beauty_mobile` не
требуется. Нужны отдельные брифы бэкенду:
1. Phase 2 extraction (`extraction_service.py`) — или явное UX-решение,
   что делать с 0% при чисто диалоговом заполнении.
2. Заземление `procedure_slug` в `propose_calendar_plan` на реальный
   каталог процедур.
