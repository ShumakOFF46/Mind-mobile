import 'package:flutter/material.dart';
import '../theme.dart';
import 'neu_palette.dart';

enum NeuDepth {
  /// Выпуклая поверхность (карточка, кнопка).
  raised,

  /// Утопленная поверхность (поле ввода, «экран», трек).
  inset,
}

/// Базовая 3D-поверхность AURA. Заливка по умолчанию — `context.aura.bg`
/// (в neumorphism поверхность совпадает с фоном), можно передать `color`.
/// `intensity` масштабирует смещение/blur теней: 1.0 — крупные карточки,
/// ~0.5 — кнопки и иконки, ~0.6 — пузыри чата.
class NeuSurface extends StatelessWidget {
  final Widget? child;
  final NeuDepth depth;
  final double radius;
  final bool circle;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final Color? color;
  final double intensity;

  const NeuSurface({
    super.key,
    this.child,
    this.depth = NeuDepth.raised,
    this.radius = 24,
    this.circle = false,
    this.padding,
    this.width,
    this.height,
    this.color,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final n = context.neu;
    final fill = color ?? context.aura.bg;
    final d = n.distance * intensity;
    final b = n.blur * intensity;
    final borderRadius = circle ? null : BorderRadius.circular(radius);
    final shape = circle ? BoxShape.circle : BoxShape.rectangle;

    if (depth == NeuDepth.inset) {
      return CustomPaint(
        foregroundPainter: _InsetPainter(
          light: n.light,
          dark: n.dark,
          distance: d * 0.6,
          blur: b * 0.7,
          radius: radius,
          circle: circle,
        ),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: fill,
            shape: shape,
            borderRadius: borderRadius,
          ),
          child: child,
        ),
      );
    }

    // Лёгкий градиент (блик → тень) даёт «объём», а не плоскую заливку.
    final hi = Color.alphaBlend(n.light.withValues(alpha: n.light.a * 0.6), fill);
    final lo = Color.alphaBlend(n.dark.withValues(alpha: n.dark.a * 0.12), fill);
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: borderRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hi, lo],
        ),
        boxShadow: [
          BoxShadow(color: n.dark, offset: Offset(d, d), blurRadius: b),
          BoxShadow(color: n.light, offset: Offset(-d, -d), blurRadius: b),
        ],
      ),
      child: child,
    );
  }
}

/// Внутренние тени: Flutter не умеет inset `BoxShadow`, поэтому рисуем
/// «рамку-дыру» вокруг фигуры, смещаем и размываем её внутрь клипа.
class _InsetPainter extends CustomPainter {
  final Color light;
  final Color dark;
  final double distance;
  final double blur;
  final double radius;
  final bool circle;

  const _InsetPainter({
    required this.light,
    required this.dark,
    required this.distance,
    required this.blur,
    required this.radius,
    required this.circle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final r = circle ? size.shortestSide / 2 : radius;
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(r));
    final hole = Path.combine(
      PathOperation.difference,
      Path()..addRect(rect.inflate(blur * 3 + distance * 2)),
      Path()..addRRect(shape),
    );
    final paint = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.5);

    canvas.save();
    canvas.clipRRect(shape);
    // Тень падает от верхне-левого края внутрь, блик — от нижне-правого.
    canvas.drawPath(hole.shift(Offset(distance, distance)), paint..color = dark);
    canvas.drawPath(hole.shift(Offset(-distance, -distance)), paint..color = light);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_InsetPainter old) =>
      old.light != light ||
      old.dark != dark ||
      old.distance != distance ||
      old.blur != blur ||
      old.radius != radius ||
      old.circle != circle;
}
