import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/app.dart';
import 'package:http/http.dart' as http;

import '../core/search/nominatim_test.dart' show uniJson;
import '../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeProfiles profiles;
  late FakeRemote remote;

  setUp(() {
    auth = FakeAuth();
    profiles = FakeProfiles();
    remote = FakeRemote();
  });

  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      HopinApp(
        auth: auth,
        profiles: profiles,
        remote: remote,
        openDatabase: memoryDatabase,
        location: FakeLocation(),
        nominatim: fakeNominatim(
          (_) async =>
              http.Response.bytes(utf8.encode(jsonEncode([uniJson])), 200),
        ),
        mapBuilder: fakeMap,
        locale: locale,
      ),
    );
    await tester.pump();
  }

  /// Unmounts the app and lets drift's stream timers run out, so no timer is
  /// left behind when the test ends.
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> openAccount(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
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
    await finish(tester);
  });

  testWidgets('signs in, lands on the map, and explains location first', (
    tester,
  ) async {
    await start(tester);
    auth.emit(null);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(auth.signIns, 1);

    auth.emit(rider);
    await tester.pumpAndSettle();
    expect(find.text('Where to?'), findsOneWidget);
    expect(find.byKey(const ValueKey('map')), findsOneWidget);
    expect(find.textContaining('Hopin uses your location'), findsOneWidget);
    expect(profiles.saved, [('r1', 'en')]);

    await openAccount(tester);
    expect(find.text('Rider access is on'), findsOneWidget);
    expect(find.text('Check again'), findsNothing);
    await finish(tester);
  });

  testWidgets('waits for rider access and can look again', (tester) async {
    await start(tester);
    auth.emit(newcomer);
    await tester.pumpAndSettle();
    await openAccount(tester);
    expect(find.text('Waiting for rider access'), findsOneWidget);
    expect(profiles.saved, isEmpty);

    await tester.tap(find.text('Check again'));
    expect(auth.refreshes, 1);

    auth.emit(rider);
    await tester.pumpAndSettle();
    expect(find.text('Rider access is on'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('searches, opens the place as on the board, and saves it', (
    tester,
  ) async {
    await start(tester);
    auth.emit(rider);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Where to?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fort');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(find.text('Colombo Fort'), findsOneWidget);
    expect(find.text('Fort, Colombo'), findsOneWidget);

    await tester.tap(find.text('Colombo Fort'));
    await tester.pumpAndSettle();
    expect(find.text('කොළඹ කොටුව'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Save place'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Uni');
    await tester.tap(find.text('Uni').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('map: 1 places'), findsOneWidget);
    expect(remote.puts.single.$2, containsPair('name', 'Uni'));
    await finish(tester);
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
    await finish(tester);
  });

  testWidgets('signs out back to the sign-in page', (tester) async {
    await start(tester);
    auth.emit(rider);
    await tester.pumpAndSettle();
    await openAccount(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(auth.signOuts, 1);
    expect(find.text('Continue with Google'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('speaks Tamil when asked', (tester) async {
    await start(tester, locale: const Locale('ta'));
    auth.emit(null);
    await tester.pumpAndSettle();
    expect(find.text('Google மூலம் தொடரவும்'), findsOneWidget);

    auth.emit(newcomer);
    await tester.pumpAndSettle();
    expect(find.text('எங்கே போக வேண்டும்?'), findsOneWidget);
    await finish(tester);
  });
}
