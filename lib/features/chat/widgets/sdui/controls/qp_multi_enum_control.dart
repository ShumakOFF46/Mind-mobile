import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme.dart';
import '../../../models/sdui/questionnaire_prompt_models.dart';

/// multi_enum + multi_select=true: чипы с множественным выбором и явным
/// подтверждением кнопкой. Отправляется ОДНО сообщение со списком
/// выбранных `label` через запятую — временное решение до появления
/// batch-контракта под repeating_by_reference (см. x_submission_contract
/// схемы), не изобретать свой формат сериализации сверх этого.
class QpMultiEnumControl extends StatefulWidget {
  final SduiQuestion question;
  final void Function(String text) onSendMessage;

  const QpMultiEnumControl({
    super.key,
    required this.question,
    required this.onSendMessage,
  });

  @override
  State<QpMultiEnumControl> createState() => _QpMultiEnumControlState();
}

class _QpMultiEnumControlState extends State<QpMultiEnumControl> {
  final Set<String> _selectedValues = {};
  bool _submitted = false;

  void _toggle(String value) {
    if (_submitted) return;
    setState(() {
      if (_selectedValues.contains(value)) {
        _selectedValues.remove(value);
      } else {
        _selectedValues.add(value);
      }
    });
  }

  void _confirm() {
    if (_submitted || _selectedValues.isEmpty) return;
    final options = widget.question.options ?? const [];
    final labels = options
        .where((o) => _selectedValues.contains(o.value))
        .map((o) => o.label)
        .join(', ');
    setState(() => _submitted = true);
    widget.onSendMessage(labels);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final options = widget.question.options ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize:       MainAxisSize.min,
      children: [
        Wrap(
          spacing:   8,
          runSpacing: 8,
          children: options.map((opt) {
            final isSelected = _selectedValues.contains(opt.value);
            return FilterChip(
              key:      ValueKey(opt.value),
              label:    Text(opt.label, style: const TextStyle(fontSize: 13)),
              selected: isSelected,
              onSelected: _submitted ? null : (_) => _toggle(opt.value),
              selectedColor:   c.accent,
              backgroundColor: c.aiBubble,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : c.textDark,
              ),
              side: BorderSide(color: c.hint.withOpacity(0.3)),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed:
              (!_submitted && _selectedValues.isNotEmpty) ? _confirm : null,
          child: Text(context.l10n.qpDoneButton),
        ),
      ],
    );
  }
}
