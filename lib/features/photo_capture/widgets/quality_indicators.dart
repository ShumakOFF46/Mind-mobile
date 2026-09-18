import 'package:flutter/material.dart';
import '../../../core/theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../services/quality_checker.dart';

/// Плашки с индикаторами качества фото.
/// Показывает ✓ или ⚠ для каждого параметра.
class QualityIndicators extends StatelessWidget {
  final QualityMetrics metrics;

  const QualityIndicators({
    super.key,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.aura;
    final l10n = context.l10n;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _IndicatorChip(
          icon: '💡',
          label: l10n.captureIndicatorLighting,
          isGood: metrics.lighting == 'good',
          colors: colors,
        ),
        _IndicatorChip(
          icon: '📐',
          label: l10n.captureIndicatorAngle,
          isGood: metrics.yaw.abs() <= 15 && metrics.pitch.abs() <= 15,
          colors: colors,
        ),
        _IndicatorChip(
          icon: '🎯',
          label: l10n.captureIndicatorPosition,
          isGood: metrics.faceRatio >= 0.3 && metrics.faceRatio <= 0.7,
          colors: colors,
        ),
        _IndicatorChip(
          icon: '📏',
          label: l10n.captureIndicatorDistance,
          isGood: metrics.sharpness >= 0.7,
          colors: colors,
        ),
      ],
    );
  }
}

class _IndicatorChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool isGood;
  final AuraColorScheme colors;

  const _IndicatorChip({
    required this.icon,
    required this.label,
    required this.isGood,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isGood ? colors.accent.withOpacity(0.2) : colors.hint.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGood ? colors.accent : colors.hint,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            isGood ? '✓' : '⚠',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isGood ? colors.accent : colors.hint,
            ),
          ),
        ],
      ),
    );
  }
}