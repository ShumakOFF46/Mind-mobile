import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/neu/neu_button.dart';
import '../core/neu/neu_surface.dart';
import '../core/theme.dart';
import 'calendar_mini_button.dart';

// Тексты захардкожены намеренно: это showcase (страница отсмотра), не продуктовый UI.

/// Макет главного экрана чата: верхняя панель (с приветствием), окно переписки, ввод.
class ChatMock extends StatelessWidget {
  const ChatMock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(c: c),
        const SizedBox(height: 24),
        // Окно переписки — утопленное, сообщения внутри — выпуклые.
        NeuSurface(
          depth: NeuDepth.inset,
          radius: 28,
          intensity: 0.9,
          padding: const EdgeInsets.fromLTRB(14, 18, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12, right: 44),
                  child: _Bubble(
                    text: 'Привет! Я AURA. Расскажите про вашу кожу, и я подберу уход.',
                    color: c.aiBubble,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12, left: 44),
                  child: _Bubble(
                    text: 'Кожа сухая, особенно зимой.',
                    color: c.userBubble,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6, right: 44),
                  child: _Bubble(
                    text: 'Поняла. Подберём мягкое очищение и плотный крем.',
                    color: c.aiBubble,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _InputMock(c: c),
      ],
    );
  }
}

/// Верхняя панель одной строкой: [Календарь] [AURA сверху + приветствие
/// снизу] [Профиль]. Название выровнено по верху кнопок, приветствие — по низу.
/// Кнопки 132 px; на узких экранах уменьшаются, чтобы в центре осталось
/// не меньше `minMiddle` под название и приветствие.
class _TopBar extends StatelessWidget {
  final AuraColorScheme c;
  const _TopBar({required this.c});

  static const _gap = 10.0;
  static const _minMiddle = 104.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final size = math.min(132.0, (box.maxWidth - 2 * _gap - _minMiddle) / 2);
      return SizedBox(
        height: size,
        child: Row(
          children: [
            CalendarMiniButton(size: size, onTap: () {}),
            const SizedBox(width: _gap),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text('AURA',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              color: c.textDark,
                              fontSize: 22,
                              height: 1,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 4,
                            )),
                        const SizedBox(width: 4),
                        Icon(Icons.auto_awesome, color: c.accent, size: 14),
                      ]),
                    ),
                  ),
                  NeuSurface(
                    radius: 22,
                    intensity: 0.6,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Добро пожаловать,',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              color: c.textSub,
                              fontSize: 15,
                              height: 1.1,
                              fontWeight: FontWeight.w500,
                            )),
                        Text('Анна',
                            style: TextStyle(
                              fontFamily: 'CormorantGaramond',
                              color: c.textDark,
                              fontSize: 24,
                              height: 1.1,
                              fontWeight: FontWeight.w600,
                            )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _gap),
            NeuButton(
              circle: true,
              width: size,
              height: size,
              intensity: 0.8,
              onTap: () {},
              child: Icon(Icons.person_outline, color: c.textDark, size: size * 0.47),
            ),
          ],
        ),
      );
    });
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final Color color;

  const _Bubble({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      radius: 20,
      intensity: 0.6,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(text,
          style: TextStyle(color: context.aura.textDark, fontSize: 15, height: 1.4)),
    );
  }
}

class _InputMock extends StatelessWidget {
  final AuraColorScheme c;
  const _InputMock({required this.c});

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      depth: NeuDepth.inset,
      radius: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          NeuButton(
            circle: true,
            width: 36,
            height: 36,
            color: c.aiBubble,
            onTap: () {},
            child: Icon(Icons.attach_file_rounded, color: c.textDark, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text('Напишите сообщение…',
                style: TextStyle(color: c.textSub, fontSize: 15)),
          ),
          NeuButton(
            circle: true,
            width: 38,
            height: 38,
            color: c.accent,
            onTap: () {},
            child: Icon(Icons.send_rounded, color: c.bg, size: 19),
          ),
        ],
      ),
    );
  }
}

/// Галерея примитивов в духе образца: карточка, «экран», трек, кнопки.
class NeuGallery extends StatefulWidget {
  const NeuGallery({super.key});

  @override
  State<NeuGallery> createState() => _NeuGalleryState();
}

class _NeuGalleryState extends State<NeuGallery> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NeuSurface(
          radius: 32,
          color: c.surface,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              NeuSurface(
                depth: NeuDepth.inset,
                radius: 18,
                intensity: 0.8,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                child: Text('09:21',
                    style: TextStyle(color: c.textDark, fontSize: 34, letterSpacing: 4)),
              ),
              const Spacer(),
              Text('Monday', style: TextStyle(color: c.textDark, fontSize: 20)),
            ],
          ),
        ),
        const SizedBox(height: 28),
        NeuSurface(
          depth: NeuDepth.inset,
          radius: 16,
          height: 32,
          padding: const EdgeInsets.all(6),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: 0.29,
            heightFactor: 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(colors: [
                  c.accent,
                  c.accent.withValues(alpha: 0.6),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            NeuSurface(radius: 24, width: 72, height: 96, color: c.aiBubble),
            const NeuSurface(depth: NeuDepth.inset, radius: 24, width: 72, height: 96),
            NeuButton(
              circle: true,
              width: 72,
              height: 72,
              intensity: 1,
              color: c.surface,
              onTap: () => setState(() => _taps++),
              child: Text('$_taps', style: TextStyle(color: c.textDark, fontSize: 24)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Center(
          child: Text('слева — выпуклая, по центру — утопленная, справа — нажми',
              style: TextStyle(color: c.hint, fontSize: 12)),
        ),
      ],
    );
  }
}
