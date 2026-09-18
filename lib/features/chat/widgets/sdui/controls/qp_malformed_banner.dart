import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme.dart';

/// Показывается вместо questions[0], когда бэкенд нарушил собственный
/// контракт: input_mode="buttons" без валидных options[] (schema
/// questionnaire_prompt.v1 требует minItems: 2). Отдельная категория от
/// generic "неизвестный type/input_mode" (QpPlainLabel) — там сервер мог
/// легитимно уйти вперёд версией схемы; здесь тип/input_mode клиенту
/// известны, просто бэкенд прислал невалидные данные для них.
///
/// Решение оркестратора (malformed buttons UX, сессия 2026-08-31): вопрос
/// скрывается целиком (label/revalidation-hint/контрол не рендерятся
/// вообще — см. QuestionnairePromptBlock.build()), показывается только
/// этот баннер. Свободный текстовый ответ как обходной путь НЕ
/// предлагается — часть таких вопросов safety-критична
/// (restriction:*/symptom:*), клиент не должен создавать иллюзию, что
/// печатный текст эквивалентен структурированному тапу по кнопке.
/// Телеметрия сознательно не добавлена — не приоритет этой сессии.
class QpMalformedBanner extends StatelessWidget {
  const QpMalformedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;

    return Container(
      key: const Key('qp_malformed_banner'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.hint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 16, color: c.textSub),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.qpMalformedButtonsBanner,
              style: TextStyle(color: c.textSub, fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
