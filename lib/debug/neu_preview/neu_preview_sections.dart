import 'package:flutter/material.dart';
import '../../core/neu/neu_button.dart';
import '../../core/neu/neu_surface.dart';
import '../../core/theme.dart';

// Тексты захардкожены намеренно: это debug-превью, не продуктовый UI.

/// Макет главного экрана чата: верхняя панель, приветствие, пузыри, ввод.
class ChatMock extends StatelessWidget {
  const ChatMock({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _TopBar(c: c),
        const SizedBox(height: 20),
        Center(
          child: NeuSurface(
            radius: 28,
            intensity: 0.7,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            child: Text('Добро пожаловать, Анна',
                style: TextStyle(
                  fontFamily: 'CormorantGaramond',
                  color: c.textDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                )),
          ),
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6, right: 60),
            child: _Bubble(
              text: 'Привет! Я AURA. Расскажите про вашу кожу, и я подберу уход.',
              color: c.aiBubble,
              depth: NeuDepth.raised,
              borderColor: c.strokePink,
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 60),
            child: _Bubble(
              text: 'Кожа сухая, особенно зимой.',
              color: c.userBubble,
              depth: NeuDepth.inset,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InputMock(c: c),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final AuraColorScheme c;
  const _TopBar({required this.c});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            NeuButton(
              width: 44,
              height: 44,
              radius: 13,
              color: c.surface,
              borderColor: c.strokeGreen,
              onTap: () {},
              child: Icon(Icons.calendar_month_outlined, color: c.textDark, size: 22),
            ),
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.bg, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        Row(children: [
          Text('AURA',
              style: TextStyle(
                fontFamily: 'CormorantGaramond',
                color: c.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
              )),
          const SizedBox(width: 4),
          Icon(Icons.auto_awesome, color: c.accent, size: 14),
        ]),
        NeuButton(
          circle: true,
          width: 44,
          height: 44,
          color: c.surface,
          borderColor: c.strokeGreen,
          onTap: () {},
          child: Icon(Icons.person_outline, color: c.textDark, size: 24),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final Color color;
  final NeuDepth depth;
  final Color? borderColor;

  const _Bubble({
    required this.text,
    required this.color,
    required this.depth,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return NeuSurface(
      depth: depth,
      radius: 20,
      intensity: 0.6,
      color: color,
      borderColor: borderColor,
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
            borderColor: c.strokePink,
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
            borderColor: c.strokeGreen,
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
        Text('Примитивы', style: TextStyle(color: c.textSub, fontSize: 13)),
        const SizedBox(height: 16),
        NeuSurface(
          radius: 32,
          color: c.surface,
          borderColor: c.strokeGreen,
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
            NeuSurface(radius: 24, width: 72, height: 96, color: c.aiBubble, borderColor: c.strokePink),
            const NeuSurface(depth: NeuDepth.inset, radius: 24, width: 72, height: 96),
            NeuButton(
              circle: true,
              width: 72,
              height: 72,
              intensity: 1,
              color: c.surface,
              borderColor: c.strokeGreen,
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
