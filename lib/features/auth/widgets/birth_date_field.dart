import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';

/// Дата рождения — date picker поверх read-only поля, визуально
/// согласовано с полем имени (CONTRACT_legal_consent_gate_v4.md §2).
class BirthDateField extends StatelessWidget {
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;

  const BirthDateField({super.key, required this.value, required this.onChanged});

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked != null) onChanged(picked);
  }

  String _format(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.${d.year}';

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return SizedBox(
      height: 52,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _pick(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerLeft,
          child: Text(
            value != null ? _format(value!) : l.legalBirthDatePlaceholder,
            style: TextStyle(
              fontSize: 16,
              color: value != null ? c.textDark : c.hint,
            ),
          ),
        ),
      ),
    );
  }
}
