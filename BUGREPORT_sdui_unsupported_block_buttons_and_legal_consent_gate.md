# BUGREPORT: "Блок не поддерживается" — buttons (подтверждено) + legal_consent_gate (вероятная причина, не 100%)

Источник: скриншот чата (22:14–22:17) + трейс Langfuse одного хода
(22:17:11, два tool call: `show_buttons`, `show_questionnaire_prompt`
slug `legal_consent_medical`), приложены Mobile 2026-09-10.

---

## 1. `buttons` — подтверждено статическим анализом, не новая находка

`sdui_block_dispatcher.dart` осознанно не диспетчеризует `type: "buttons"`
(комментарий в файле: "buttons/media/link/gif... вне объёма"). Это тот же
Medium-finding, что уже был в первом conformance-аудите
(`REPORT_mobile_actuality_audit.md`) — не закрыт с тех пор.

**Изменение контекста**: раньше `buttons` был периферийным, сейчас
system-промпт AURA активно вызывает `show_buttons` для выбора согласий —
это уже mainline UX, не край. Нужен отдельный бриф на реализацию
(quick-reply тапы, отправка `value` а не текста лейбла — по аналогии с
`questionnaire_prompt`).

## 2. `legal_consent_gate` — зарегистрирован в диспетчере, но есть реальный edge-case мисматч

Проверено построчно: `legal_gate_block.py::build_legal_consent_gate_block()`
против `legal_consent_gate_models.dart::LegalConsentGateBlockData.fromJson()`
и сида `MEDICAL_SCHEMA` (`legal:medical_data_accepted` /
`legal:model_training_accepted`) — формат `type`/`reason`/
`questions[].key`/`questions[].label` совпадает. В штатном случае
(`reason: "initial"`, вопросы есть) парсинг обязан проходить.

**Найденный реальный мисматч**: `ui_block_tools.py::
_handle_show_legal_consent_gate()` — при `gate_result.blocked_reason ==
"declined"` `questions` остаётся `[]` осознанно (backend считает, что
переспрашивать вопросы не нужно, факт отказа уже зафиксирован). Мобильный
парсер:

```dart
if (rawQuestions is! List || rawQuestions.isEmpty) {
  throw const FormatException('legal_consent_gate: missing questions');
}
```

безусловно требует непустой список — в `reason: "declined"` блок
**гарантированно** не отрендерится и уйдёт в `UnknownBlock`. Это баг
независимо от того, воспроизвёлся ли он именно в приложенном трейсе (там,
судя по диалогу, вероятнее `reason: "initial"` с непустыми вопросами —
для него по коду мисматча не видно).

**Не подтверждено без доступа к устройству**: не могу проверить, какая
именно ветка сработала у Олега — для точного ответа нужен
`debugPrint('SDUI: malformed legal_consent_gate block: $e')` из консоли
Flutter на устройстве, либо подтверждение версии установленной сборки
(включает ли она коммит `908a462`, фичу Legal Consent Gate v4).

---

## Рекомендации

1. Бэкенд: либо не отправлять `legal_consent_gate` вовсе при
   `reason == "declined"` без вопросов (просто текстовым ответом от LLM),
   либо мобильный клиент должен принимать пустой `questions[]` для этого
   `reason` как валидный (рендерить как read-only уведомление "вы ранее
   отказались", без списка вопросов) — нужно решение оркестратора, какая
   сторона правильная по контракту.
2. Мобильный агент: отдельный бриф на `buttons`-блок — уже не опционально,
   активно используется в проде.
3. Для точной диагностики трейса 22:17 — нужны Flutter debug-логи с
   устройства и версия установленной сборки.
