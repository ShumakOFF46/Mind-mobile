import 'dart:async';
import 'package:flutter/material.dart';
import 'neu_surface.dart';

/// Кнопка на `NeuSurface`: при нажатии «вдавливается» (raised → inset),
/// при отпускании возвращается в выпуклую. `onTap == null` — кнопка
/// неактивна, без эффекта нажатия.
///
/// Состояние нажатия берётся из `Listener` (сырые события указателя), а не
/// из `onTapDown` жеста: у `GestureDetector` `onTapDown` приходит с задержкой
/// или только в момент отпускания, из-за чего быстрый тап не был виден.
/// Минимальное время «вдавленного» состояния — `_minPress`, чтобы даже
/// мгновенный тап заметно «продавливал» кнопку.
///
/// Нужны явные `width`/`height` (содержимое центрируется).
class NeuButton extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget child;
  final double? width;
  final double? height;
  final double radius;
  final bool circle;
  final Color? color;
  final double intensity;
  final Color? borderColor;

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
    this.borderColor,
  });

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  static const _minPress = Duration(milliseconds: 140);

  bool _pressed = false;
  DateTime? _downAt;
  Timer? _releaseTimer;

  void _onDown(PointerDownEvent _) {
    if (widget.onTap == null) return;
    _releaseTimer?.cancel();
    _downAt = DateTime.now();
    if (!_pressed) setState(() => _pressed = true);
  }

  void _onUp(PointerEvent _) {
    if (!_pressed) return;
    final held = DateTime.now().difference(_downAt ?? DateTime.now());
    final rest = _minPress - held;
    if (rest <= Duration.zero) {
      _release();
    } else {
      _releaseTimer = Timer(rest, _release);
    }
  }

  void _release() {
    if (mounted && _pressed) setState(() => _pressed = false);
  }

  @override
  void dispose() {
    _releaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _onDown,
      onPointerUp: _onUp,
      onPointerCancel: _onUp,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.97 : 1,
          duration: const Duration(milliseconds: 90),
          child: NeuSurface(
            depth: _pressed ? NeuDepth.inset : NeuDepth.raised,
            width: widget.width,
            height: widget.height,
            radius: widget.radius,
            circle: widget.circle,
            color: widget.color,
            // Утопленное состояние чуть сильнее, чтобы нажатие читалось.
            intensity: widget.intensity * (_pressed ? 1.25 : 1),
            borderColor: widget.borderColor,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}
