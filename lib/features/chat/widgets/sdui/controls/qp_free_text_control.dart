import 'package:flutter/material.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/theme.dart';
import '../../../models/sdui/questionnaire_prompt_models.dart';

/// input_mode=free_text — покрывает типы open_list/free_paragraph (и
/// numeric — но для него отдельный QpNumericControl с числовой
/// клавиатурой). Обычное текстовое сообщение чата; интерпретация
/// (certainty) происходит асинхронно на бэкенде, не на клиенте.
///
/// Отправка: '{label}: {value}' (не сырое значение) — см.
/// x_submission_contract.free_text схемы questionnaire_prompt.
class QpFreeTextControl extends StatefulWidget {
  final SduiQuestion question;
  final void Function(String text) onSendMessage;

  const QpFreeTextControl({
    super.key,
    required this.question,
    required this.onSendMessage,
  });

  @override
  State<QpFreeTextControl> createState() => _QpFreeTextControlState();
}

class _QpFreeTextControlState extends State<QpFreeTextControl> {
  final _controller = TextEditingController();
  bool _submitted = false;

  bool get _isParagraph => widget.question.type == 'free_paragraph';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    final l = context.l10n;

    if (_submitted) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: c.accent),
          const SizedBox(width: 6),
          Text(l.qpSubmittedLabel, style: TextStyle(color: c.textSub, fontSize: 12)),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: TextField(
            controller: _controller,
            minLines:   1,
            maxLines:   _isParagraph ? 4 : 1,
            style:      TextStyle(color: c.textDark, fontSize: 14),
            decoration: InputDecoration(
              isDense:   true,
              hintText:  l.qpFreeTextHint,
              hintStyle: TextStyle(color: c.hint, fontSize: 13),
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _submit,
          tooltip:   l.qpSendButton,
          icon: Icon(Icons.send_rounded, color: c.accent),
        ),
      ],
    );
  }
}
