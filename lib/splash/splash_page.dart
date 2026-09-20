import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

const _bgAsset = 'assets/images/splash_bg.png';
const _butterflyAsset = 'assets/images/butterfly_line.png';

/// Цвет нативного splash (Android/iOS) — фон до первого Flutter-кадра.
const _nativeSplashColor = Color(0xFFDDD3B9);

/// Стартовая страница: большая бабочка и «AURA Mind» плавно проявляются на
/// фирменном градиенте, затем fade на `next`. Нативный splash — только фон
/// (без бабочки), поэтому пользователь видит один экран, а не два.
///
/// Анимация стартует только после `precacheImage`: иначе картинки
/// декодируются уже во время fade, и бабочка «выскакивает» без проявления.
class SplashPage extends StatefulWidget {
  final WidgetBuilder next;

  /// Сколько держать экран после того, как fade-in закончился.
  final Duration hold;

  const SplashPage({
    super.key,
    required this.next,
    this.hold = const Duration(milliseconds: 1200),
  });

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  static const _fadeIn = Duration(milliseconds: 1600);

  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: _fadeIn);
  late final Animation<double> _opacity =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  late final Animation<double> _scale = Tween<double>(begin: 0.94, end: 1)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  Timer? _timer;
  bool _started = false;
  bool _bgReady = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _prepareAndRun();
  }

  Future<void> _prepareAndRun() async {
    await Future.wait([
      precacheImage(const AssetImage(_bgAsset), context),
      precacheImage(const AssetImage(_butterflyAsset), context),
    ]);
    if (!mounted) return;
    setState(() => _bgReady = true);
    // Даём кадру с фоном отрисоваться, затем запускаем проявление.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ctrl.forward();
      _timer = Timer(_fadeIn + widget.hold, _goNext);
    });
  }

  void _goNext() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 600),
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
      backgroundColor: _nativeSplashColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_bgReady) Image.asset(_bgAsset, fit: BoxFit.cover),
          Center(
            child: FadeTransition(
              opacity: _opacity,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(_butterflyAsset, width: w * 0.6),
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
