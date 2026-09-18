import 'package:flutter/material.dart';
import '../../../core/theme.dart';

/// Овал-маска для guided capture.
/// Меняет цвет в зависимости от качества фото:
/// - accent (#E8A0A0) когда всё ок
/// - hint (#9E7E7E) когда нужно исправить
class FaceOverlay extends StatelessWidget {
  final bool isGoodQuality;
  final Size previewSize;

  const FaceOverlay({
    super.key,
    required this.isGoodQuality,
    required this.previewSize,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.aura;
    final borderColor = isGoodQuality ? colors.accent : colors.hint;

    // Овал занимает 60% ширины и 70% высоты экрана
    final ovalWidth = previewSize.width * 0.6;
    final ovalHeight = previewSize.height * 0.7;

    return CustomPaint(
      size: previewSize,
      painter: _FaceOvalPainter(
        ovalWidth: ovalWidth,
        ovalHeight: ovalHeight,
        borderColor: borderColor,
      ),
    );
  }
}

class _FaceOvalPainter extends CustomPainter {
  final double ovalWidth;
  final double ovalHeight;
  final Color borderColor;

  _FaceOvalPainter({
    required this.ovalWidth,
    required this.ovalHeight,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Внешний овал (граница)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    final ovalRect = Rect.fromCenter(
      center: center,
      width: ovalWidth,
      height: ovalHeight,
    );

    canvas.drawOval(ovalRect, borderPaint);

    // Затемнение вне овала (полупрозрачный чёрный)
    final dimPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Рисуем путь вне овала
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);
  }

  @override
  bool shouldRepaint(covariant _FaceOvalPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.ovalWidth != ovalWidth ||
        oldDelegate.ovalHeight != ovalHeight;
  }
}