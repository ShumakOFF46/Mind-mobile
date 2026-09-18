import 'package:flutter/material.dart';

/// Fallback для вопроса с нераспознанным `type`/`input_mode`
/// (сервер ушёл вперёд клиента — unknown_type_or_input_mode из
/// x_submission_contract схемы). Label уже отрендерен выше в
/// QuestionnairePromptBlock — здесь сознательно ничего не рисуется,
/// т.к. интерактивных контролов для неизвестной комбинации быть не может.
class QpPlainLabel extends StatelessWidget {
  const QpPlainLabel({super.key});

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
