import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/app.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeProfiles profiles;

  setUp(() {
    auth = FakeAuth();
    profiles = FakeProfiles();
  });

  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      HopinApp(auth: auth, profiles: profiles, locale: locale),
    );
    await tester.pump();
  }

  testWidgets('waits on the start screen, then asks to sign in', (
    tester,
  ) async {
    await start(tester);
    expect(find.text('Hopin'), findsOneWidget);
    expect(find.text('Continue with Google'), findsNothing);

    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Never miss your stop.'), findsOneWidget);
  });

  testWidgets('signs in and lands home as a rider', (tester) async {
    await start(tester);
    auth.emit(null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(auth.signIns, 1);

    auth.emit(rider);
    await tester.pumpAndSettle();
    expect(find.text('Hi, Rider'), findsOneWidget);
    expect(find.text('Rider access is on'), findsOneWidget);
    expect(find.text('Check again'), findsNothing);
    expect(profiles.saved, [('r1', 'en')]);
  });

  testWidgets('waits for rider access and can look again', (tester) async {
    await start(tester);
    auth.emit(newcomer);
    await tester.pumpAndSettle();
    expect(find.text('Waiting for rider access'), findsOneWidget);
    expect(profiles.saved, isEmpty);

    await tester.tap(find.text('Check again'));
    expect(auth.refreshes, 1);

    auth.emit(rider);
    await tester.pumpAndSettle();
    expect(find.text('Rider access is on'), findsOneWidget);
  });

  testWidgets('says so when sign-in fails', (tester) async {
    auth.nextError = StateError('network');
    await start(tester);
    auth.emit(null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();
    expect(
      find.text("Sign-in didn't work. Check your internet and try again."),
      findsOneWidget,
    );
  });

  testWidgets('signs out back to the sign-in page', (tester) async {
    await start(tester);
    auth.emit(rider);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('speaks Tamil when asked', (tester) async {
    await start(tester, locale: const Locale('ta'));
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Google மூலம் தொடரவும்'), findsOneWidget);

    auth.emit(newcomer);
    await tester.pumpAndSettle();
    expect(find.text('வணக்கம், Rider'), findsOneWidget);
    expect(find.text('பயணி அனுமதிக்காகக் காத்திருக்கிறது'), findsOneWidget);
  });
}
