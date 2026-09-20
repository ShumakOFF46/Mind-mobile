import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() {
  runApp(const AuraMindApp());
}

/// Точка входа AURA Mind.
///
/// Это временная заглушка шаблона: экраны, роутинг и фичи будут
/// добавлены по мере разработки приложения.
class AuraMindApp extends StatelessWidget {
  const AuraMindApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AURA Mind',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const Scaffold(
        body: Center(
          child: Text('AURA Mind — в разработке'),
        ),
      ),
    );
  }
}
