import 'package:flutter/material.dart';
import '../core/theme.dart';

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.aura;
    return Padding(
      padding: const EdgeInsets.only(top: 44, bottom: 16),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: c.textSub,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 3,
        ),
      ),
    );
  }
}
