import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';

/// Показывается поверх формы экрана 2 при `blocked_reason: "declined"`
/// (контракт §3). НЕ dead-end — кнопка возвращает к форме, чекбоксы
/// сохраняют последнее состояние (форма не сбрасывается).
class DeclinedConsentView extends StatelessWidget {
  final VoidCallback onBack;

  const DeclinedConsentView({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final l = context.l10n;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: c.accent, size: 48),
          const SizedBox(height: 16),
          Text(
            l.legalRegionalDeclinedTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: c.textDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l.legalRegionalDeclinedMessage,
            style: TextStyle(fontSize: 13, color: c.textSub, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: Text(l.legalRegionalDeclinedRetryButton),
            ),
          ),
        ],
      ),
    );
  }
}
