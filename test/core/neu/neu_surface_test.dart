import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aura_mind/core/neu/neu_button.dart';
import 'package:aura_mind/core/neu/neu_surface.dart';
import 'package:aura_mind/core/theme.dart';

Widget _host(Widget child, {ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    );

void main() {
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    testWidgets('NeuSurface raised/inset/circle render without errors (${entry.key})',
        (tester) async {
      await tester.pumpWidget(_host(
        Column(mainAxisSize: MainAxisSize.min, children: const [
          NeuSurface(width: 120, height: 60, child: Text('raised')),
          NeuSurface(depth: NeuDepth.inset, width: 120, height: 60, child: Text('inset')),
          NeuSurface(circle: true, width: 48, height: 48),
        ]),
        theme: entry.value,
      ));
      expect(find.text('raised'), findsOneWidget);
      expect(find.text('inset'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('NeuButton: calls onTap and toggles raised -> inset while pressed',
      (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(
      NeuButton(onTap: () => taps++, width: 48, height: 48, child: const Icon(Icons.add)),
    ));
    NeuDepth depth() => tester.widget<NeuSurface>(find.byType(NeuSurface)).depth;

    expect(depth(), NeuDepth.raised);
    final gesture = await tester.startGesture(tester.getCenter(find.byType(NeuButton)));
    await tester.pump();
    expect(depth(), NeuDepth.inset);
    await gesture.up();
    await tester.pump();
    expect(depth(), NeuDepth.raised);
    expect(taps, 1);
  });

  testWidgets('NeuButton with onTap == null never enters pressed state', (tester) async {
    await tester.pumpWidget(_host(
      const NeuButton(width: 48, height: 48, child: Icon(Icons.add)),
    ));
    final gesture = await tester.startGesture(tester.getCenter(find.byType(NeuButton)));
    await tester.pump();
    expect(tester.widget<NeuSurface>(find.byType(NeuSurface)).depth, NeuDepth.raised);
    await gesture.up();
  });
}
