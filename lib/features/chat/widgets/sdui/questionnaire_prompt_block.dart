import 'package:flutter/material.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme.dart';
import '../../models/sdui/questionnaire_prompt_models.dart';
import 'controls/qp_buttons_control.dart';
import 'controls/qp_free_text_control.dart';
import 'controls/qp_malformed_banner.dart';
import 'controls/qp_multi_enum_control.dart';
import 'controls/qp_numeric_control.dart';
import 'controls/qp_plain_label.dart';

/// Рендер SDUI-блока `questionnaire_prompt` внутри AI-реплики чата.
///
/// Контракт: contracts/sdui_blocks/questionnaire_prompt.schema.json.
/// Интерактивен ТОЛЬКО questions[0] — остальные элементы массива
/// (repeating_by_reference-разворот) приходят следующими ходами чата,
/// не клиентской пагинацией по этому же блоку.
///
/// ⚠ Malformed buttons UX (решение оркестратора, сессия 2026-08-31): если
/// questions[0] — input_mode="buttons" без валидных options[] (контрактное
/// нарушение бэкенда, schema требует minItems: 2), вопрос скрывается
/// ЦЕЛИКОМ (label/revalidation-hint/прогресс/контрол не рендерятся),
/// показывается только компактный QpMalformedBanner. Свободный текстовый
/// ответ как обходной путь НЕ предлагается — часть таких вопросов
/// safety-критична (restriction:*/symptom:*), клиент не создаёт иллюзию,
/// что печатный текст эквивалентен структурированному тапу по кнопке.
/// Телеметрия сознательно не добавлена — не приоритет этой сессии.
class QuestionnairePromptBlock extends StatelessWidget {
  final QuestionnairePromptBlockData data;
  final void Function(String text) onSendMessage;

  const QuestionnairePromptBlock({
    super.key,
    required this.data,
    required this.onSendMessage,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final question = data.questions.first;
    final isMalformed = question.isMalformedButtonsWithoutOptions;

    return Container(
      margin:  const EdgeInsets.only(top: 6, right: 40),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        c.surface,
        borderRadius: BorderRadius.circular(16),
        border:       Border.all(color: c.hint.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize:       MainAxisSize.min,
        children: [
          if (data.intro != null && data.intro!.trim().isNotEmpty) ...[
            Text(
              data.intro!,
              style: TextStyle(color: c.textDark, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 8),
          ],
          if (isMalformed)
            const QpMalformedBanner()
          else ...[
            if (data.questions.length > 1) ...[
              Text(
                context.l10n.qpProgressLabel(1, data.questions.length),
                style: TextStyle(
                  color:      c.textSub,
                  fontSize:   11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              question.label,
              style: TextStyle(
                color:      c.textDark,
                fontSize:   15,
                fontWeight: FontWeight.w600,
                height:     1.4,
              ),
            ),
            if (question.isRevalidation) ...[
              const SizedBox(height: 4),
              Text(
                context.l10n.qpRevalidationHint,
                style: TextStyle(
                  color:      c.textSub,
                  fontSize:   11,
                  fontStyle:  FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 10),
            _buildControl(question),
          ],
        ],
      ),
    );
  }

  Widget _buildControl(SduiQuestion q) {
    // Неизвестный type/input_mode (сервер ушёл вперёд клиента) — label
    // уже показан выше, контролов для него нет и не должно быть.
    // ⚠ Malformed-вопросы (isMalformedButtonsWithoutOptions) сюда не
    // попадают вовсе — build() перехватывает их раньше, эта функция
    // обслуживает только генуинно неизвестные клиенту type/input_mode.
    if (!q.isInteractive) return const QpPlainLabel();

    if (q.type == 'numeric') {
      return QpNumericControl(question: q, onSendMessage: onSendMessage);
    }

    if (q.inputMode == 'buttons') {
      if (q.type == 'multi_enum' && q.multiSelect) {
        return QpMultiEnumControl(question: q, onSendMessage: onSendMessage);
      }
      // multi_enum с multi_select=false трактуется как single-select —
      // контракт явно этот кейс не описывает, консервативный дефолт.
      return QpButtonsControl(question: q, onSendMessage: onSendMessage);
    }

    // free_text — покрывает open_list/free_paragraph
    return QpFreeTextControl(question: q, onSendMessage: onSendMessage);
  }
}
