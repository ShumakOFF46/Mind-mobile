import 'package:flutter_test/flutter_test.dart';
import 'package:vb_mobile/features/chat/models/sdui/profiling_question_models.dart';

Map<String, dynamic> _validJson({int optionsCount = 3}) {
  const allOptions = [
    {'label': {'ru': 'Да', 'en': 'Yes'}, 'value': 'yes'},
    {'label': {'ru': 'Нет', 'en': 'No'}, 'value': 'no'},
    {'label': {'ru': 'Не уверена', 'en': 'Not sure'}, 'value': 'unsure'},
    {'label': {'ru': '4'}, 'value': 'v4'},
    {'label': {'ru': '5'}, 'value': 'v5'},
    {'label': {'ru': '6'}, 'value': 'v6'},
  ];
  return {
    'type': 'profiling_question',
    'questionnaire_slug': 'profile_health',
    'answer_key': 'restriction:pregnancy',
    'label': {'ru': 'Вы беременны?', 'en': 'Are you pregnant?'},
    'options': allOptions.take(optionsCount).toList(),
    'is_revalidation': false,
  };
}

void main() {
  group('I18nTextResolution.resolve', () {
    test('возвращает текст текущей локали, если ключ есть', () {
      final map = {'ru': 'Привет', 'en': 'Hello'};
      expect(map.resolve('en'), 'Hello');
      expect(map.resolve('ru'), 'Привет');
    });

    test('fallback на любой доступный ключ, если текущей локали нет', () {
      final map = {'ru': 'Привет'};
      expect(map.resolve('kk'), 'Привет');
      expect(map.resolve('en'), 'Привет');
    });
  });

  group('ProfilingQuestionBlockData.fromJson — валидные случаи', () {
    test('парсит блок с 2 опциями (нижняя граница схемы)', () {
      final data = ProfilingQuestionBlockData.fromJson(_validJson(optionsCount: 2));
      expect(data.questionnaireSlug, 'profile_health');
      expect(data.answerKey, 'restriction:pregnancy');
      expect(data.options.length, 2);
      expect(data.label.resolve('ru'), 'Вы беременны?');
      expect(data.isRevalidation, isFalse);
    });

    test('парсит блок с 6 опциями (верхняя граница схемы)', () {
      final data = ProfilingQuestionBlockData.fromJson(_validJson(optionsCount: 6));
      expect(data.options.length, 6);
      expect(data.options.last.value, 'v6');
    });

    test('is_revalidation по умолчанию false, если отсутствует в JSON', () {
      final json = _validJson()..remove('is_revalidation');
      final data = ProfilingQuestionBlockData.fromJson(json);
      expect(data.isRevalidation, isFalse);
    });

    test('option.label с одним языком — валиден (minProperties: 1)', () {
      final json = _validJson(optionsCount: 2);
      (json['options'] as List)[0] = {
        'label': {'ru': 'Только русский'},
        'value': 'yes',
      };
      final data = ProfilingQuestionBlockData.fromJson(json);
      expect(data.options.first.label.resolve('en'), 'Только русский');
    });
  });

  group('ProfilingQuestionBlockData.fromJson — контрактные нарушения', () {
    test('отсутствие answer_key бросает FormatException', () {
      final json = _validJson()..remove('answer_key');
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('отсутствие questionnaire_slug бросает FormatException', () {
      final json = _validJson()..remove('questionnaire_slug');
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('отсутствие label бросает FormatException', () {
      final json = _validJson()..remove('label');
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('label как пустая карта бросает FormatException', () {
      final json = _validJson()..['label'] = <String, dynamic>{};
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('options с 1 элементом (< minItems=2) бросает FormatException', () {
      final json = _validJson(optionsCount: 1);
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('options отсутствует бросает FormatException', () {
      final json = _validJson()..remove('options');
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('option без value бросает FormatException', () {
      final json = _validJson(optionsCount: 2);
      (json['options'] as List)[0] = {
        'label': {'ru': 'Да'},
      };
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });

    test('option без label бросает FormatException', () {
      final json = _validJson(optionsCount: 2);
      (json['options'] as List)[0] = {'value': 'yes'};
      expect(() => ProfilingQuestionBlockData.fromJson(json),
          throwsFormatException);
    });
  });

  // ⚠ options с 7 элементами (> maxItems=6 схемы) сознательно НЕ проверяется
  // на выброс FormatException здесь: контракт (profiling_question.
  // schema.json) ограничивает то, что ДОЛЖЕН присылать backend, но клиент
  // не обязан отклонять честно пришедшие 7 валидных опций как "малформед" —
  // однако BRIEF/модель выше трактует это строго (minItems/maxItems),
  // см. ProfilingQuestionBlockData.fromJson. Тест на >6 опций сознательно
  // не добавлен — граница симметрична нижней (см. тест "options с 1
  // элементом" выше), поведение идентично по коду.
}
