import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Одна строка карточки "Attributes": иконка + капс-подпись слева,
/// значение справа, тонкий разделитель снизу (кроме последней строки).
class BeautyAttributeRow extends StatelessWidget {
  const BeautyAttributeRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final IconData icon;
  final String   label;
  final String   value;
  final bool     showDivider;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: c.accent),
              const SizedBox(width: 10),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: c.textSub,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.textDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: c.hint.withOpacity(0.25)),
      ],
    );
  }
}
