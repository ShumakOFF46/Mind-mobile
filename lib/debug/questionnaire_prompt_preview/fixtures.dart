/// Фикстуры для визуальной приёмки questionnaire_prompt (планшет/эмулятор).
///
/// ⚠ ВАЖНО: поля здесь — `key`/`block_version`/`intro`, как их реально
/// читает `SduiQuestion.fromJson()`/`QuestionnairePromptBlockData.fromJson()`
/// (lib/features/chat/models/sdui/questionnaire_prompt_models.dart).
/// Живой payload, приведённый в BRIEF_mobile_questionnaire_prompt_visual_qa.md,
/// использует другие имена полей (`answer_key`/`version`/`title`) — если это
/// не опечатка при написании брифа, а реальный ответ бэкенда, блок сейчас
/// НЕ рендерится как questionnaire_prompt в проде, а падает в UnknownBlock.
/// Нужно сверить с сырым SSE-телом / Langfuse-трейсом отдельно.
library;

const _allergyOptions = [
  {'value': 'none', 'label': 'нет реакции'},
  {'value': 'mild', 'label': 'лёгкая'},
  {'value': 'moderate', 'label': 'умеренная'},
  {'value': 'severe', 'label': 'выраженная'},
  {'value': 'life_threatening_anaphylaxis', 'label': 'угрожающая жизни/анафилаксия'},
];

/// Фикстура 1 — реальный кейс из живого прогона 2026-08-12
/// (conversation_id=a60c2fc9-...), самый длинный лейбл кнопки —
/// естественный стресс-тест на перенос/overflow текста.
const fixtureLiveAllergyLatex = {
  'type': 'questionnaire_prompt',
  'block_version': 1,
  'questionnaire_slug': 'profile_health',
  'intro': null,
  'questions': [
    {
      'key': 'profile:health:allergy_severity:latex',
      'type': 'enum',
      'input_mode': 'buttons',
      'label': 'Насколько выраженная реакция на латекс?',
      'options': _allergyOptions,
      'is_revalidation': false,
    },
  ],
};

/// Фикстура 2 — repeating_by_reference, два под-вопроса разом
/// (в реальных диалогах обычно приходит по одному, но контракт формально
/// это не запрещает — см. universal_dialog_engine.md §2, пример 12.11).
/// Интерактивен должен быть только questions[0] (латекс), пыльца —
/// индикатор прогресса "Вопрос 1 из 2".
const fixtureRepeatingAllergies = {
  'type': 'questionnaire_prompt',
  'block_version': 1,
  'questionnaire_slug': 'profile_health',
  'intro': null,
  'questions': [
    {
      'key': 'profile:health:allergy_severity:latex',
      'type': 'enum',
      'input_mode': 'buttons',
      'label': 'Насколько выраженная реакция на латекс?',
      'options': _allergyOptions,
      'is_revalidation': false,
    },
    {
      'key': 'profile:health:allergy_severity:pollen',
      'type': 'enum',
      'input_mode': 'buttons',
      'label': 'Насколько выраженная реакция на пыльцу?',
      'options': _allergyOptions,
      'is_revalidation': false,
    },
  ],
};

/// Фикстура 3 — is_revalidation: true, safety-критичный tri_state
/// (restriction:pregnancy, см. universal_dialog_engine.md §2, пример 12.5).
const fixtureRevalidationPregnancy = {
  'type': 'questionnaire_prompt',
  'block_version': 1,
  'questionnaire_slug': 'profile_health',
  'intro': null,
  'questions': [
    {
      'key': 'restriction:pregnancy',
      'type': 'tri_state',
      'input_mode': 'buttons',
      'label': 'Ты отмечала беременность как «не уверена» два месяца назад — как сейчас?',
      'options': [
        {'value': 'yes', 'label': 'да'},
        {'value': 'no', 'label': 'нет'},
        {'value': 'unsure', 'label': 'не уверена'},
      ],
      'is_revalidation': true,
    },
  ],
};

/// Фикстура 4 — malformed: input_mode=buttons без options.
/// Ожидаемо: SduiQuestion.fromJson() помечает inputMode как
/// `_malformed_buttons_without_options` -> isInteractive=false ->
/// QuestionnairePromptBlock рисует QpPlainLabel (SizedBox.shrink()).
/// На экране будет виден только текст вопроса, без контролов ниже —
/// это ожидаемо, не баг парсинга (см. предупреждение в чате про UX).
const fixtureMalformedButtonsNoOptions = {
  'type': 'questionnaire_prompt',
  'block_version': 1,
  'questionnaire_slug': 'profile_health',
  'intro': null,
  'questions': [
    {
      'key': 'profile:health:allergy_severity:shellfish',
      'type': 'enum',
      'input_mode': 'buttons',
      'label': 'Насколько выраженная реакция на морепродукты?',
      'is_revalidation': false,
      // 'options' намеренно отсутствует
    },
  ],
};

/// (title, assistantText, блок для рендера) — используется превью-экраном.
///
/// assistantText — реалистичная реплика LLM перед блоком (по аналогии с
/// universal_dialog_engine.md, примеры 12.11/12.5), НЕ пустая строка —
/// пустой text ранее давал на скрине пустую серую "таблетку" над карточкой,
/// артефакт фикстур, не баг ChatBubble/SduiBlockDispatcher.
const previewFixtures = <(String, String, Map<String, dynamic>)>[
  (
    '1. Live payload — allergy latex (длинный лейбл)',
    'Поняла, отметила аллергию на латекс.',
    fixtureLiveAllergyLatex,
  ),
  (
    '2. Repeating — latex + pollen (2 под-вопроса)',
    'Поняла, отметила оба — латекс и пыльцу.',
    fixtureRepeatingAllergies,
  ),
  (
    '3. Revalidation — pregnancy tri_state',
    'Есть минутка уточнить пару вещей про самочувствие?',
    fixtureRevalidationPregnancy,
  ),
  (
    '4. Malformed — buttons без options',
    'Уточню ещё один момент.',
    fixtureMalformedButtonsNoOptions,
  ),
];
