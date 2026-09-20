import 'package:flutter/material.dart';
import '../theme.dart';

/// Параметры «мягкого 3D» (neumorphism): блик сверху-слева и тень
/// снизу-справа. Цвета производные от палитры AURA (`AuraColors`) —
/// собственной цветовой гаммы здесь нет, поэтому смена палитры в
/// `theme.dart` автоматически меняет и 3D-эффект.
class NeuPalette {
  /// Блик (источник света — сверху-слева).
  final Color light;

  /// Тень (снизу-справа).
  final Color dark;

  /// Базовое смещение теней, px (умножается на `intensity` поверхности).
  final double distance;

  /// Базовый blur теней, px (умножается на `intensity` поверхности).
  final double blur;

  const NeuPalette._({
    required this.light,
    required this.dark,
    required this.distance,
    required this.blur,
  });

  static final NeuPalette lightMode = NeuPalette._(
    light: Colors.white.withValues(alpha: 0.95),
    dark: AuraColors.lightTextSub.withValues(alpha: 0.32),
    distance: 6,
    blur: 14,
  );

  static final NeuPalette darkMode = NeuPalette._(
    light: Colors.white.withValues(alpha: 0.07),
    dark: Colors.black.withValues(alpha: 0.55),
    distance: 6,
    blur: 14,
  );
}

extension NeuTheme on BuildContext {
  NeuPalette get neu => Theme.of(this).brightness == Brightness.dark
      ? NeuPalette.darkMode
      : NeuPalette.lightMode;
}
