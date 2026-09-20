import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/neu/neu_button.dart';
import '../core/neu/neu_surface.dart';
import '../core/theme.dart';

// Тексты захардкожены намеренно: showcase, не продуктовый UI.

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

double _contrast(Color a, Color b) {
  final l1 = a.computeLuminance(), l2 = b.computeLuminance();
  return (math.max(l1, l2) + 0.05) / (math.min(l1, l2) + 0.05);
}

/// Семь цветов референса «Dietitian».
class PaletteSection extends StatelessWidget {
  const PaletteSection({super.key});

  static const _colors = <(String, Color)>[
    ('savory sage', AuraColors.savorySage),
    ('avocado smoothie', AuraColors.avocadoSmoothie),
    ('blush beet', AuraColors.blushBeet),
    ('peach protein', AuraColors.peachProtein),
    ('oat latte', AuraColors.oatLatte),
    ('honey oatmilk', AuraColors.honeyOatmilk),
    ('coconut cream', AuraColors.coconutCream),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return LayoutBuilder(builder: (context, box) {
      final w = (box.maxWidth - 16) / 2;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (name, color) in _colors)
            SizedBox(
              width: w,
              child: NeuSurface(
                radius: 22,
                intensity: 0.5,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.hint.withValues(alpha: 0.4)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(name,
                        style: TextStyle(
                            color: c.textDark,
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600)),
                    Text(_hex(color), style: TextStyle(color: c.textSub, fontSize: 12)),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }
}

/// Роли темы (текущая тема) и контраст текстовых цветов на каждой заливке.
class RolesSection extends StatelessWidget {
  const RolesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    final roles = <(String, Color)>[
      ('bg — основной фон', c.bg),
      ('aiBubble — сообщения AURA', c.aiBubble),
      ('userBubble — сообщения пользователя', c.userBubble),
      ('surface — плашки', c.surface),
      ('accent — акцент', c.accent),
      ('strokeGreen — контур на зелёном', c.strokeGreen),
      ('strokePink — контур на розовом', c.strokePink),
    ];
    final fills = <(String, Color)>[
      ('bg', c.bg),
      ('aiBubble', c.aiBubble),
      ('userBubble', c.userBubble),
      ('surface', c.surface),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeuSurface(
          radius: 22,
          intensity: 0.5,
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              for (final (name, color) in roles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.hint.withValues(alpha: 0.5)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(name, style: TextStyle(color: c.textDark, fontSize: 14)),
                    ),
                    Text(_hex(color), style: TextStyle(color: c.textSub, fontSize: 12)),
                  ]),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        for (final (name, fill) in fills) ...[
          NeuSurface(
            radius: 20,
            intensity: 0.5,
            color: fill,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('на $name', style: TextStyle(color: c.textSub, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 6),
                _sample('textDark — заголовок и текст', c.textDark, fill, 18),
                _sample('textSub — вторичный текст', c.textSub, fill, 16),
                _sample('hint — подсказки', c.hint, fill, 16),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text('AA: ≥ 4.5 для основного текста, ≥ 3 для крупного.',
            style: TextStyle(color: c.hint, fontSize: 11)),
      ],
    );
  }

  Widget _sample(String label, Color fg, Color bg, double size) {
    final r = _contrast(fg, bg);
    final mark = r >= 4.5 ? 'AA ✓' : (r >= 3 ? 'крупный ✓' : '✗');
    return Row(children: [
      Expanded(child: Text(label, style: TextStyle(color: fg, fontSize: size))),
      Text('${r.toStringAsFixed(1)} · $mark', style: TextStyle(color: fg, fontSize: 11)),
    ]);
  }
}

/// Кнопки: зелёная (avocado + savory), розовая (peach + blush), акцентная.
class ButtonsSection extends StatelessWidget {
  const ButtonsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    Widget label(String t, Color color) => Text(t,
        style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600));
    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: [
        NeuButton(
          width: 130, height: 46, radius: 23, intensity: 0.6,
          color: c.surface, onTap: () {},
          child: label('Зелёная', c.textDark),
        ),
        NeuButton(
          width: 130, height: 46, radius: 23, intensity: 0.6,
          color: c.aiBubble, onTap: () {},
          child: label('Розовая', c.textDark),
        ),
        NeuButton(
          width: 130, height: 46, radius: 23, intensity: 0.6,
          color: c.accent, onTap: () {},
          child: label('Акцент', c.bg),
        ),
        NeuButton(
          width: 130, height: 46, radius: 23, intensity: 0.6,
          onTap: null,
          child: label('Неактивна', c.hint),
        ),
      ],
    );
  }
}
