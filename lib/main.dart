import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'showcase/showcase_page.dart';
import 'splash/splash_page.dart';

void main() {
  runApp(const AuraMindApp());
}

/// Точка входа AURA Mind: splash с бабочкой → showcase-страница
/// (палитра, шрифты, 3D-компоненты) до появления реальных экранов.
class AuraMindApp extends StatefulWidget {
  const AuraMindApp({super.key});

  @override
  State<AuraMindApp> createState() => _AuraMindAppState();
}

class _AuraMindAppState extends State<AuraMindApp> {
  final ValueNotifier<ThemeMode> _themeMode = ValueNotifier(ThemeMode.light);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) => MaterialApp(
        title: 'AURA Mind',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: SplashPage(
          next: (_) => ShowcasePage(themeMode: _themeMode),
        ),
      ),
    );
  }
}
