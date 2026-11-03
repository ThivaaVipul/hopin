import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/app.dart';

void main() {
  testWidgets('starts in English with the app name', (tester) async {
    await tester.pumpWidget(const HopinApp());
    await tester.pumpAndSettle();

    expect(find.text('Hopin'), findsOneWidget);
    final context = tester.element(find.text('Hopin'));
    expect(Localizations.localeOf(context), const Locale('en'));
  });

  testWidgets('runs in Tamil when asked', (tester) async {
    await tester.pumpWidget(const HopinApp(locale: Locale('ta')));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Hopin'));
    expect(Localizations.localeOf(context), const Locale('ta'));
  });
}
