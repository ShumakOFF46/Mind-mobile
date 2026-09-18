/// Модели данных SDUI-блока `questionnaire_prompt`.
/// Контракт: contracts/sdui_blocks/questionnaire_prompt.schema.json
///
/// Разбор defensive: любое несоответствие обязательным полям бросает
/// FormatException — вызывающий код (SduiBlockDispatcher) обязан ловить
/// это и уходить в UnknownBlock, а не ронять экран чата.
library;

/// Sentinel input_mode для вопросов, где бэкенд заявил input_mode=buttons,
/// но options[] отсутствует ИЛИ пуст — контрактное нарушение (schema
/// questionnaire_prompt.v1 требует minItems: 2 для options). См.
/// SduiQuestion.isMalformedButtonsWithoutOptions.
const _kMalformedButtonsInputMode = '_malformed_buttons_without_options';

class SduiQuestionOption {
  final String value;
  final String label;

  const SduiQuestionOption({required this.value, required this.label});

  factory SduiQuestionOption.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    final label = json['label'];
    if (value is! String || label is! String) {
      throw const FormatException('option.value/label должны быть строками');
    }
    return SduiQuestionOption(value: value, label: label);
  }
}

class SduiNumericConstraints {
  final String? unit;
  final num?    min;
  final num?    max;

  const SduiNumericConstraints({this.unit, this.min, this.max});

  factory SduiNumericConstraints.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SduiNumericConstraints();
    return SduiNumericConstraints(
      unit: json['unit'] as String?,
      min:  json['min'] as num?,
      max:  json['max'] as num?,
    );
  }
}

/// Известные значения `question.type` по контракту. Значение вне списка —
/// не ошибка парсинга (сервер мог уйти вперёд клиента версией схемы),
/// просто рендерится как обычный текст, см. [SduiQuestion.isInteractive].
const kKnownQuestionTypes = {
  'bool', 'tri_state', 'enum', 'multi_enum',
  'numeric', 'open_list', 'free_paragraph',
};

const kKnownInputModes = {'buttons', 'free_text'};

class SduiQuestion {
  final String key;         // читается из JSON-ключа `answer_key` (контракт),
                             // имя Dart-поля оставлено как есть — не
                             // переименовываю, чтобы не задеть controls/*,
                             // которые на это поле уже ссылаются (вне
                             // объёма этого брифа, см. BRIEF п.3)
  final String type;        // сырая строка, валидация значения — не забота парсинга
  final String inputMode;   // сырая строка
  final String label;
  final String? itemLabel;  // repeating_by_reference: человекочитаемое имя
                             // элемента-источника, подставляется в label
                             // по плейсхолдеру {item_label} (см.
                             // universal_dialog_engine.md §2). Ранее в
                             // модели отсутствовало вовсе.
  final String? groupLabel;
  final bool   isRevalidation;
  final List<SduiQuestionOption>? options;
  final bool   multiSelect;
  final SduiNumericConstraints? numericConstraints;

  const SduiQuestion({
    required this.key,
    required this.type,
    required this.inputMode,
    required this.label,
    this.itemLabel,
    this.groupLabel,
    this.isRevalidation = false,
    this.options,
    this.multiSelect = false,
    this.numericConstraints,
  });

  bool get isKnownType      => kKnownQuestionTypes.contains(type);
  bool get isKnownInputMode => kKnownInputModes.contains(inputMode);

  /// false → см. x_submission_contract.unknown_type_or_input_mode:
  /// label рендерится текстом, без интерактивных контролов.
  bool get isInteractive => isKnownType && isKnownInputMode;

  /// Малформед по вине бэкенда (не "клиент не знает тип/режим" — тот
  /// случай уже покрыт isInteractive==false). Тип/input_mode здесь
  /// клиенту ИЗВЕСТНЫ, но options[] нарушает собственный контракт
  /// бэкенда (schema требует minItems: 2). Решение оркестратора
  /// (malformed buttons UX, сессия 2026-08-31): вопрос с этим флагом
  /// скрывается целиком на уровне QuestionnairePromptBlock, не проваливается
  /// в общий QpPlainLabel-фоллбэк, который предназначен для генуинно
  /// незнакомых клиенту type/input_mode.
  bool get isMalformedButtonsWithoutOptions =>
      inputMode == _kMalformedButtonsInputMode;

  factory SduiQuestion.fromJson(Map<String, dynamic> json) {
    // ⚠ Контрактный JSON-ключ — `answer_key` (см. contracts/sdui_blocks/
    // questionnaire_prompt.schema.json). `key` — не существует в реальном
    // ответе бэкенда (см. REPORT_mobile_verify_questionnaire_prompt_
    // field_names.md, 2026-08-16).
    final key       = json['answer_key'];
    final type      = json['type'];
    final inputMode = json['input_mode'];
    final label     = json['label'];
    if (key is! String || type is! String || inputMode is! String || label is! String) {
      throw const FormatException(
          'question.answer_key/type/input_mode/label обязательны и должны быть строками');
    }

    final rawOptions = json['options'];
    final options = rawOptions is List
        ? rawOptions
            .map((o) => SduiQuestionOption.fromJson(Map<String, dynamic>.from(o as Map)))
            .toList()
        : null;

    // Схема требует options[] (minItems: 2) при input_mode=buttons. Если
    // сервер прислал buttons без options ИЛИ с пустым массивом — оба
    // случая контрактное нарушение бэкенда, не просто "клиент не знает
    // тип". До 2026-08-31 ловился только null/отсутствие ключа — пустой
    // массив (`"options": []`, именно так на практике выглядит нарушение
    // minItems:2) проходил мимо этой проверки (rawOptions is List
    // истинно даже для []), safeInputMode оставался 'buttons', вопрос
    // рендерился как QpButtonsControl с 0 кнопками — реальный механизм
    // находки "malformed buttons UX-тупик" (диагностика 2026-08-16/17,
    // продуктовое решение принято 2026-08-31, см. ProjectFull.md).
    final safeInputMode =
        (inputMode == 'buttons' && (options == null || options.isEmpty))
            ? _kMalformedButtonsInputMode
            : inputMode;

    return SduiQuestion(
      key:            key,
      type:           type,
      inputMode:      safeInputMode,
      label:          label,
      itemLabel:      json['item_label'] as String?,
      groupLabel:     json['group_label'] as String?,
      isRevalidation: json['is_revalidation'] as bool? ?? false,
      options:        options,
      multiSelect:    json['multi_select'] as bool? ?? false,
      numericConstraints: json['numeric_constraints'] != null
          ? SduiNumericConstraints.fromJson(
              Map<String, dynamic>.from(json['numeric_constraints'] as Map))
          : null,
    );
  }
}

class QuestionnairePromptBlockData {
  final int    blockVersion;
  final String questionnaireSlug;
  final String? intro;
  final List<SduiQuestion> questions;

  const QuestionnairePromptBlockData({
    required this.blockVersion,
    required this.questionnaireSlug,
    this.intro,
    required this.questions,
  });

  factory QuestionnairePromptBlockData.fromJson(Map<String, dynamic> json) {
    // ⚠ Контрактные JSON-ключи — `version`/`title` (см.
    // contracts/sdui_blocks/questionnaire_prompt.schema.json). Ни
    // `block_version`, ни `intro` в реальном ответе бэкенда не
    // существуют (см. REPORT_mobile_verify_questionnaire_prompt_
    // field_names.md, 2026-08-16). Имя Dart-поля `intro` сознательно
    // оставлено как есть (не переименовано в `title`) — чтобы не
    // задевать questionnaire_prompt_block.dart, ссылающийся на
    // `data.intro` (вне объёма фикса, см. BRIEF п.3); меняется только
    // JSON-ключ чтения, не публичный интерфейс модели.
    final blockVersion = json['version'];
    final slug         = json['questionnaire_slug'];
    final rawQuestions = json['questions'];
    if (blockVersion is! int || slug is! String || rawQuestions is! List) {
      throw const FormatException(
          'version/questionnaire_slug/questions обязательны');
    }
    final questions = rawQuestions
        .map((q) => SduiQuestion.fromJson(Map<String, dynamic>.from(q as Map)))
        .toList();

    return QuestionnairePromptBlockData(
      blockVersion:      blockVersion,
      questionnaireSlug: slug,
      intro:             json['title'] as String?,
      questions:         questions,
    );
  }
}
