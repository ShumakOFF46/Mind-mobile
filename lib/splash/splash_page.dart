import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

/// Стартовая страница: бабочка на фирменном градиенте, затем fade на `next`.
/// Фон и бабочка совпадают с нативным splash (Android/iOS), чтобы не было
/// «скачка» между нативным и Flutter-кадром.
class SplashPage extends StatefulWidget {
  final WidgetBuilder next;
  final Duration hold;

  const SplashPage({
    super.key,
    required this.next,
    this.hold = const Duration(milliseconds: 2200),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();
  late final Animation<double> _curve =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.hold, _goNext);
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (ctx, _, _) => widget.next(ctx),
      transitionsBuilder: (_, anim, _, child) =>
          FadeTransition(opacity: anim, child: child),
    ));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/splash_bg.png', fit: BoxFit.cover),
          Center(
            child: FadeTransition(
              opacity: _curve,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.92, end: 1).animate(_curve),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/butterfly_line.png',
                        width: w * 0.6),
                    const SizedBox(height: 28),
                    const Text(
                      'AURA Mind',
                      style: TextStyle(
                        fontFamily: 'CormorantGaramond',
                        color: AuraColors.lightTextDark,
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
