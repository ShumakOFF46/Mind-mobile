import 'package:flutter/material.dart';
import '../../../../../core/theme.dart';
import '../../../models/sdui/questionnaire_prompt_models.dart';

/// Single-select кнопки: bool / tri_state / enum (input_mode=buttons,
/// без multi_select). Тап сразу отправляет `option.label` как обычное
/// сообщение чата — `option.value` на сервер отдельно не уходит (см.
/// x_submission_contract схемы, идентично поведению generic buttons-блока).
class QpButtonsControl extends StatefulWidget {
  final SduiQuestion question;
  final void Function(String text) onSendMessage;

  const QpButtonsControl({
    super.key,
    required this.question,
    required this.onSendMessage,
  });

  @override
  State<QpButtonsControl> createState() => _QpButtonsControlState();
}

class _QpButtonsControlState extends State<QpButtonsControl> {
  String? _selectedValue;

  void _handleTap(SduiQuestionOption option) {
    if (_selectedValue != null) return; // уже отвечено — игнорируем повторный тап
    setState(() => _selectedValue = option.value);
    widget.onSendMessage(option.label);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final options = widget.question.options ?? const [];

    return Wrap(
      spacing:   8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = _selectedValue == opt.value;
        final isDisabled = _selectedValue != null && !isSelected;
        return OutlinedButton(
          key: ValueKey(opt.value),
          onPressed: _selectedValue == null ? () => _handleTap(opt) : null,
          style: OutlinedButton.styleFrom(
            backgroundColor: isSelected ? c.accent : Colors.transparent,
            foregroundColor: isSelected ? Colors.white : c.textDark,
            side: BorderSide(
              color: isDisabled ? c.hint.withOpacity(0.3) : c.accent,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(opt.label, style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }
}
