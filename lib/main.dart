import 'package:flutter/material.dart';

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
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.deepPurple),
      home: const Scaffold(
        body: Center(
          child: Text('AURA Mind — в разработке'),
        ),
      ),
    );
  }
}
