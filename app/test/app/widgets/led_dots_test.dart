import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/led_dots.dart';

List<Color?> dotColors(WidgetTester tester) => tester
    .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
    .map((dot) => (dot.decoration as BoxDecoration?)?.color)
    .toList();

Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  theme: hopinTheme(Brightness.light),
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduceMotion),
    child: Center(child: child),
  ),
);

void main() {
  const c = HopinColors.light;

  testWidgets('lights the lit ones and dims the rest', (tester) async {
    await tester.pumpWidget(host(const LedDots(count: 5, lit: 2)));
    expect(dotColors(tester), [
      c.amber,
      c.amber,
      c.amberDim,
      c.amberDim,
      c.amberDim,
    ]);
  });

  testWidgets('lights up one after another', (tester) async {
    await tester.pumpWidget(host(const LedDots(count: 4, lightUp: true)));
    expect(dotColors(tester), everyElement(c.amberDim));
    await tester.pumpAndSettle();
    expect(dotColors(tester), everyElement(c.amber));
  });

  testWidgets('is simply on with reduced motion', (tester) async {
    await tester.pumpWidget(
      host(const LedDots(count: 4, lightUp: true), reduceMotion: true),
    );
    await tester.pump();
    expect(dotColors(tester), everyElement(c.amber));
  });
}
