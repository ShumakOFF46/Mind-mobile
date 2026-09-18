// Regression-тест десериализации SDUI-блока `questionnaire_prompt`.
//
// JSON ниже — ПРЯМОЙ SQL-дамп agent.messages.blocks для
// conversation_id=a60c2fc9-a2af-40b1-8485-8d678fe801b4 (запрос выполнен
// оркестратором 2026-08-17):
//
//   SELECT blocks FROM agent.messages
//   WHERE conversation_id = 'a60c2fc9-a2af-40b1-8485-8d678fe801b4'
//     AND blocks IS NOT NULL;
//
// Это НЕ пример из schema.json — это буквально то, что реально ушло
// клиенту с бэкенда. Расхождения с примером из контракта (известны
// заранее, задокументированы в ProjectFull.md, CHANGELOG 2026-08-11,
// Шаг 2 диагностики finish_reason — не новая находка):
//   - item_label реально ВСЕГДА null, текст элемента уже подставлен
//     целиком в label ("...реакция на латекс?", не "...на {item_label}?")
//   - в реальном payload 5 options (schema-пример показывал 4) — есть
//     "none"/"нет реакции", и value "life_threatening_anaphylaxis"
//     (не "life_threatening", как в примере схемы)

import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/features/chat/models/sdui/questionnaire_prompt_models.dart';

/// Дословный SQL-дамп agent.messages.blocks, conversation_id=
/// a60c2fc9-a2af-40b1-8485-8d678fe801b4.
const _kLivePayloadJson = <String, dynamic>{
  'type': 'questionnaire_prompt',
  'title': null,
  'version': 1,
  'questions': [
    {
      'type': 'enum',
      'label': 'Насколько выраженная реакция на латекс?',
      'options': [
        {'label': 'нет реакции', 'value': 'none'},
        {'label': 'лёгкая', 'value': 'mild'},
        {'label': 'умеренная', 'value': 'moderate'},
        {'label': 'выраженная', 'value': 'severe'},
        {'label': 'угрожающая жизни/анафилаксия', 'value': 'life_threatening_anaphylaxis'},
      ],
      'answer_key': 'profile:health:allergy_severity:latex',
      'input_mode': 'buttons',
      'item_label': null,
      'is_revalidation': false,
    },
  ],
  'questionnaire_slug': 'profile_health',
};

void main() {
  group('QuestionnairePromptBlockData.fromJson — реальный live-payload (не schema-пример)', () {
    test('парсит version/questionnaire_slug/title без FormatException', () {
      final data = QuestionnairePromptBlockData.fromJson(_kLivePayloadJson);

      expect(data.blockVersion, 1);
      expect(data.questionnaireSlug, 'profile_health');
      expect(data.intro, isNull); // title:null в реальном payload
      expect(data.questions, hasLength(1));
    });

    test('SduiQuestion.fromJson читает answer_key корректно, item_label реально ВСЕГДА null', () {
      final data = QuestionnairePromptBlockData.fromJson(_kLivePayloadJson);
      final q = data.questions.single;

      expect(q.key, 'profile:health:allergy_severity:latex');
      // ⚠ НЕ 'латекс' — реальный бэкенд не подставляет item_label как
      // отдельное поле, текст уже вплетён в label целиком. Известное,
      // задокументированное расхождение с примером в schema.json, не
      // баг этого фикса.
      expect(q.itemLabel, isNull);
      expect(q.type, 'enum');
      expect(q.inputMode, 'buttons');
      expect(q.label, 'Насколько выраженная реакция на латекс?');
      expect(q.isRevalidation, isFalse);
      expect(q.options, hasLength(5));
      expect(
        q.options!.map((o) => o.value),
        containsAll(['none', 'mild', 'moderate', 'severe', 'life_threatening_anaphylaxis']),
      );
      expect(q.isInteractive, isTrue);
    });

    test(
      'regression-guard: JSON под СТАРЫЙ (сломанный) формат '
      '(block_version/key/intro) больше не парсится молча как валидный',
      () {
        const legacyWrongFormatJson = <String, dynamic>{
          'block_version': 1, // контракт этого не шлёт — только version
          'questionnaire_slug': 'profile_health',
          'intro': null, // контракт этого не шлёт — только title
          'questions': [
            {
              'key': 'profile:health:allergy_severity:latex', // контракт — answer_key
              'type': 'enum',
              'input_mode': 'buttons',
              'label': 'Насколько выраженная реакция?',
              'options': [
                {'value': 'mild', 'label': 'Лёгкая'},
              ],
            },
          ],
        };

        expect(
          () => QuestionnairePromptBlockData.fromJson(legacyWrongFormatJson),
          throwsFormatException,
        );
      },
    );
  });
}
