/// Модель SDUI-блока `profiling_question`.
/// Контракт: contracts/sdui_blocks/profiling_question.schema.json,
/// CONTRACT_deterministic_profiling_answer_v1.md §1
/// (+ ADDENDUM/ADDENDUM2 — правки tool-сигнатуры и tier1-директивы на
/// backend, СХЕМУ блока не затрагивают).
///
/// ⚠ КЛЮЧЕВОЕ ОТЛИЧИЕ от questionnaire_prompt_models.dart: там `label`/
/// `option.label` — уже ГОТОВАЯ строка (backend резолвит локаль сам,
/// see REPORT_mobile_verify_questionnaire_prompt_field_names.md). Здесь
/// схема прямо требует i18n-карту `{"ru": "...", "en": "..."}`
/// (minProperties: 1) — резолюция под текущую локаль приложения
/// происходит НА КЛИЕНТЕ (см. [I18nTextResolution.resolve]),
/// fallback на любой доступный ключ карты, если текущей локали нет
/// (BRIEF_mobile_deterministic_profiling_answer.md §1).
///
/// Разбор defensive: любое несоответствие обязательным полям бросает
/// FormatException — вызывающий код (SduiBlockDispatcher) обязан ловить
/// это и уходить в UnknownBlock, а не ронять экран чата (тот же принцип,
/// что у всех остальных SDUI-моделей в проекте).
library;

/// Локализованная карта locale -> текст. Минимум один валидный ключ
/// гарантирован парсингом (см. [_parseI18nMap]) — schema.json требует
/// minProperties: 1.
extension I18nTextResolution on Map<String, String> {
  /// Резолюция под текущую локаль приложения. Если точного совпадения
  /// нет — берём первое доступное значение карты (порядок вставки JSON
  /// сохраняется `Map`-парсингом `dart:convert`, но какое именно значение
  /// попадёт первым — не контрактно важно: контракт гарантирует лишь, что
  /// оно валидно и непусто).
  String resolve(String languageCode) => this[languageCode] ?? values.first;
}

Map<String, String> _parseI18nMap(dynamic raw, String fieldName) {
  if (raw is! Map || raw.isEmpty) {
    throw FormatException(
        'profiling_question: $fieldName должен быть непустой i18n-картой locale->text');
  }
  final result = <String, String>{};
  raw.forEach((key, value) {
    if (key is String && value is String && value.isNotEmpty) {
      result[key] = value;
    }
  });
  if (result.isEmpty) {
    throw FormatException(
        'profiling_question: $fieldName не содержит ни одной валидной строки locale->text');
  }
  return result;
}

class ProfilingQuestionOption {
  final Map<String, String> label; // i18n-карта, см. класс-doc
  final String value;

  const ProfilingQuestionOption({required this.label, required this.value});

  factory ProfilingQuestionOption.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    if (value is! String || value.isEmpty) {
      throw const FormatException(
          'profiling_question: option.value обязателен и не может быть пустым');
    }
    final label = _parseI18nMap(json['label'], 'option.label');
    return ProfilingQuestionOption(label: label, value: value);
  }
}

class ProfilingQuestionBlockData {
  final String questionnaireSlug;
  final String answerKey;
  final Map<String, String> label; // i18n-карта, см. класс-doc
  final List<ProfilingQuestionOption> options;
  final bool isRevalidation;

  const ProfilingQuestionBlockData({
    required this.questionnaireSlug,
    required this.answerKey,
    required this.label,
    required this.options,
    this.isRevalidation = false,
  });

  factory ProfilingQuestionBlockData.fromJson(Map<String, dynamic> json) {
    final slug = json['questionnaire_slug'];
    final answerKey = json['answer_key'];
    if (slug is! String || slug.isEmpty) {
      throw const FormatException(
          'profiling_question: questionnaire_slug обязателен и не может быть пустым');
    }
    if (answerKey is! String || answerKey.isEmpty) {
      throw const FormatException(
          'profiling_question: answer_key обязателен и не может быть пустым');
    }
    final label = _parseI18nMap(json['label'], 'label');

    // Schema: options — minItems: 2, maxItems: 6. Границы проверяются
    // здесь же, а не только визуально в виджете — контрактное нарушение
    // должно уводить блок целиком в UnknownBlock на уровне диспетчера,
    // не рендериться с недопустимым числом кнопок (тот же принцип, что
    // malformed-buttons-guard у questionnaire_prompt, только строже:
    // там разрешалось 0, здесь контракт явно запрещает <2 и >6).
    final rawOptions = json['options'];
    if (rawOptions is! List || rawOptions.length < 2 || rawOptions.length > 6) {
      throw const FormatException(
          'profiling_question: options[] обязателен, minItems=2, maxItems=6');
    }
    final options = rawOptions
        .map((o) =>
            ProfilingQuestionOption.fromJson(Map<String, dynamic>.from(o as Map)))
        .toList();

    return ProfilingQuestionBlockData(
      questionnaireSlug: slug,
      answerKey: answerKey,
      label: label,
      options: options,
      isRevalidation: json['is_revalidation'] as bool? ?? false,
    );
  }
}
