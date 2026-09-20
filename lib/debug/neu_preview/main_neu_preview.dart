import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'neu_preview_sections.dart';

/// Превью 3D-слоя (core/neu). Запуск:
///   flutter run -t lib/debug/neu_preview/main_neu_preview.dart
/// Только для визуальной проверки, в основное приложение не входит.
void main() => runApp(const NeuPreviewApp());

class NeuPreviewApp extends StatefulWidget {
  const NeuPreviewApp({super.key});

  @override
  State<NeuPreviewApp> createState() => _NeuPreviewAppState();
}

class _NeuPreviewAppState extends State<NeuPreviewApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: _NeuPreviewPage(
        dark: _dark,
        onToggle: (v) => setState(() => _dark = v),
      ),
    );
  }
}

class _NeuPreviewPage extends StatelessWidget {
  final bool dark;
  final ValueChanged<bool> onToggle;

  const _NeuPreviewPage({required this.dark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Text('3D preview', style: TextStyle(color: c.textSub, fontSize: 13)),
                const Spacer(),
                Text(dark ? 'dark' : 'light', style: TextStyle(color: c.textSub, fontSize: 13)),
                Switch(value: dark, activeColor: c.accent, onChanged: onToggle),
              ],
            ),
            const SizedBox(height: 8),
            const ChatMock(),
            const SizedBox(height: 40),
            const NeuGallery(),
          ],
        ),
      ),
    );
  }
}
