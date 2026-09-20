import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'neu_sections.dart';
import 'palette_section.dart';
import 'section_title.dart';
import 'typography_section.dart';

/// Страница отсмотра дизайна: палитра, роли и контраст, шрифты,
/// макет чата и 3D-примитивы. Переключатель темы — сверху.
class ShowcasePage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeMode;

  const ShowcasePage({super.key, required this.themeMode});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        // На планшетах держим контент в колонке ~640 px по центру.
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              children: [
                Row(
                  children: [
                    Text('AURA Mind',
                        style: TextStyle(
                          color: c.textDark,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3,
                        )),
                    const Spacer(),
                    Text(dark ? 'dark' : 'light',
                        style: TextStyle(color: c.textSub, fontSize: 13)),
                    Switch(
                      value: dark,
                      activeColor: c.accent,
                      onChanged: (v) =>
                          themeMode.value = v ? ThemeMode.dark : ThemeMode.light,
                    ),
                  ],
                ),
                const SectionTitle('Палитра'),
                const PaletteSection(),
                const SectionTitle('Роли и контраст текста'),
                const RolesSection(),
                const SectionTitle('Кнопки и контуры'),
                const ButtonsSection(),
                const SectionTitle('Шрифты'),
                const TypographySection(),
                const SectionTitle('Главный экран чата (макет)'),
                const ChatMock(),
                const SectionTitle('3D-примитивы'),
                const NeuGallery(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
