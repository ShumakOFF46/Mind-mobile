import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme.dart';
import '../../../models/sdui/questionnaire_prompt_models.dart';

/// type=numeric — текстовое поле с числовой клавиатурой. min/max/unit
/// показаны только как UX-подсказка (hint), без блокирующей клиентской
/// валидации — финальная валидация всегда на сервере.
///
/// Отправка: '{label}: {value}' (не сырое значение) — см.
/// x_submission_contract.free_text схемы questionnaire_prompt.
/// Причина: серверная экстракция свободного текста не может надёжно
/// опираться только на порядок сообщений в истории чата, в отличие от
/// buttons, где значение и так ограничено заранее известным options.
/// Совпадает с поведением старого generic-блока 'input'.
class QpNumericControl extends StatefulWidget {
  final SduiQuestion question;
  final void Function(String text) onSendMessage;

  const QpNumericControl({
    super.key,
    required this.question,
    required this.onSendMessage,
  });

  @override
  State<QpNumericControl> createState() => _QpNumericControlState();
}

class _QpNumericControlState extends State<QpNumericControl> {
  final _controller = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _hint(BuildContext context) {
    final l = context.l10n;
    final constraints = widget.question.numericConstraints;
    final parts = <String>[];
    if (constraints?.min != null) {
      parts.add('${l.qpNumericMinLabel}: ${constraints!.min}');
    }
    if (constraints?.max != null) {
      parts.add('${l.qpNumericMaxLabel}: ${constraints!.max}');
    }
    if (constraints?.unit != null && constraints!.unit!.isNotEmpty) {
      parts.add(constraints.unit!);
    }
    return parts.join('  ·  ');
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty || _submitted) return;
    setState(() => _submitted = true);
    widget.onSendMessage('${widget.question.label}: $value');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller:   _controller,
            enabled:      !_submitted,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style:        TextStyle(color: c.textDark, fontSize: 14),
            decoration: InputDecoration(
              isDense:   true,
              hintText:  _hint(context),
              hintStyle: TextStyle(color: c.hint, fontSize: 12),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _submitted ? null : _submit,
          tooltip:   context.l10n.qpSendButton,
          icon: Icon(
            Icons.send_rounded,
            color: _submitted ? c.hint : c.accent,
          ),
        ),
      ],
    );
  }
}
