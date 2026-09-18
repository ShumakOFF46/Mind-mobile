import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../theme.dart';

/// Переиспользуемая строка "чекбокс + текст со ссылкой на документ".
/// Используется на экране регистрации (basic_data_consent), экране
/// регионального согласия (chat_tos/personal_data) и в SDUI-блоке
/// legal_consent_gate (medical_data/model_training) —
/// CONTRACT_legal_consent_gate_v4.md, §2/§3/§6.
class ConsentCheckboxRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String prefixText;
  final String linkText;
  final VoidCallback onLinkTap;

  const ConsentCheckboxRow({
    super.key,
    required this.value,
    required this.onChanged,
    required this.prefixText,
    required this.linkText,
    required this.onLinkTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: value,
            activeColor: c.accent,
            onChanged: (v) => onChanged(v ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, color: c.textDark, height: 1.4),
                children: [
                  TextSpan(text: prefixText),
                  TextSpan(
                    text: linkText,
                    style: TextStyle(
                      color: c.accent,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onLinkTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
