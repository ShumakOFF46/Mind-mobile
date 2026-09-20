import 'package:flutter/material.dart';
import '../core/neu/neu_surface.dart';
import '../core/theme.dart';

// Тексты захардкожены намеренно: showcase, не продуктовый UI.

const _sample = 'Добро пожаловать, Анна';
const _latin = 'Live every day with ease';
const _digits = '0123456789  09:21  58%';

/// Cormorant Garamond (шрифт из beauty_mobile) и системный шрифт.
class TypographySection extends StatelessWidget {
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    TextStyle serif(double size, FontWeight w, {bool italic = false, double ls = 0}) =>
        TextStyle(
          fontFamily: 'CormorantGaramond',
          color: c.textDark,
          fontSize: size,
          fontWeight: w,
          fontStyle: italic ? FontStyle.italic : FontStyle.normal,
          letterSpacing: ls,
        );
    Widget caption(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 4),
          child: Text(t, style: TextStyle(color: c.textSub, fontSize: 11, letterSpacing: 1)),
        );

    return NeuSurface(
      radius: 26,
      intensity: 0.6,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AURA Mind', style: serif(38, FontWeight.w600, ls: 6)),
          caption('Cormorant Garamond — насыщенность'),
          for (final (w, name) in const [
            (FontWeight.w300, '300 Light'),
            (FontWeight.w400, '400 Regular'),
            (FontWeight.w500, '500 Medium'),
            (FontWeight.w600, '600 SemiBold'),
            (FontWeight.w700, '700 Bold'),
          ])
            Text('$name — $_sample', style: serif(22, w)),
          caption('Cormorant Garamond — курсив'),
          Text(_sample, style: serif(24, FontWeight.w400, italic: true)),
          Text(_latin, style: serif(22, FontWeight.w500, italic: true)),
          caption('Размеры'),
          for (final s in const [12.0, 14.0, 16.0, 20.0, 24.0, 32.0])
            Text('${s.toInt()} — $_sample', style: serif(s, FontWeight.w500)),
          caption('Цифры'),
          Text(_digits, style: serif(26, FontWeight.w500, ls: 2)),
          caption('Системный шрифт (Roboto) — как в тексте сообщений'),
          Text('$_sample. $_latin.',
              style: TextStyle(fontFamily: 'Roboto', color: c.textDark, fontSize: 15, height: 1.4)),
          Text('Подпись 10 · вторичный текст',
              style: TextStyle(fontFamily: 'Roboto', color: c.textSub, fontSize: 10)),
        ],
      ),
    );
  }
}
