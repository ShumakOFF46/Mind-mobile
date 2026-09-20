import 'package:flutter/material.dart';
import 'neu_surface.dart';

/// Кнопка на `NeuSurface`: при нажатии «вдавливается» (raised → inset).
/// `onTap == null` — кнопка неактивна, без эффекта нажатия.
class NeuButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  final Color? color;
  final double intensity;

  const NeuButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.radius = 16,
    this.circle = false,
    this.color,
    this.intensity = 0.5,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (widget.onTap == null || _pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: NeuSurface(
        depth: _pressed ? NeuDepth.inset : NeuDepth.raised,
        width: widget.width,
        height: widget.height,
        radius: widget.radius,
        circle: widget.circle,
        color: widget.color,
        intensity: widget.intensity,
        child: Center(child: widget.child),
      ),
    );
  }
}
