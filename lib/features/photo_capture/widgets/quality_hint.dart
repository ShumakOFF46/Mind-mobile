import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../services/quality_checker.dart';

/// Динамическая подсказка пользователю на основе метрик качества.
class QualityHint extends StatelessWidget {
  final QualityMetrics metrics;

  const QualityHint({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.aura;
    final l10n = context.l10n;
    final hint = _getHint(l10n);

    if (hint == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.hint.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.hint.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Color(0xFF9E7E7E)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hint,
              style: TextStyle(
                fontSize: 14,
                color: colors.textDark,
                fontFamily: 'CormorantGaramond',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String? _getHint(AppLocalizations l10n) {
    // Приоритет подсказок (от самого важного к менее важному)
    if (metrics.lighting == 'dim') {
      return l10n.captureHintLightingDim;
    }
    if (metrics.lighting == 'overexposed') {
      return l10n.captureHintLightingOverexposed;
    }
    if (metrics.sharpness < 0.7) {
      return l10n.captureHintSharpness;
    }
    if (metrics.yaw.abs() > 15 || metrics.pitch.abs() > 15) {
      return l10n.captureHintAngle;
    }
    if (metrics.faceRatio < 0.3) {
      return l10n.captureHintTooClose;
    }
    if (metrics.faceRatio > 0.7) {
      return l10n.captureHintTooFar;
    }
    return null; // Всё ок — подсказка не нужна
  }
}