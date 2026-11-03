import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/app.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/features/home/widgets/ride_board.dart';
import 'package:http/http.dart' as http;

import '../core/search/nominatim_test.dart' show uniJson;
import '../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeProfiles profiles;
  late FakeRemote remote;
  late FakeGuide guide;

  setUp(() {
    auth = FakeAuth();
    profiles = FakeProfiles();
    remote = FakeRemote();
    guide = FakeGuide();
  });

  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    LocationService? location,
  }) async {
    await tester.pumpWidget(
      HopinApp(
        auth: auth,
        profiles: profiles,
        remote: remote,
        openDatabase: memoryDatabase,
        location: location ?? FakeLocation(),
        nominatim: fakeNominatim(
          (_) async =>
              http.Response.bytes(utf8.encode(jsonEncode([uniJson])), 200),
        ),
        mapBuilder: fakeMap,
        guide: guide,
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

  /// Signed in with location on, the search's place open.
  Future<void> openPlace(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await start(
      tester,
      locale: locale,
      location: FakeLocation(
        access: LocationAccess.granted,
        here: const GeoPoint(6.9200, 79.8550),
      ),
    );
    auth.emit(rider);
    await tester.pumpAndSettle();
    final tamil = locale.languageCode == 'ta';
    await tester.tap(find.text(tamil ? 'எங்கே போக வேண்டும்?' : 'Where to?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'fort');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(
        locale.languageCode == 'ta' ? 'கொழும்பு கோட்டை' : 'Colombo Fort',
      ),
    );
    await tester.pumpAndSettle();
  }

  Color boardColour(WidgetTester tester) =>
      ((tester.widget<Container>(
                find
                    .descendant(
                      of: find.byType(RideBoard),
                      matching: find.byType(Container),
                    )
                    .first,
              )).decoration!
              as BoxDecoration)
          .color!;

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

  testWidgets('guides to the place: the board, amber at the end, End', (
    tester,
  ) async {
    guide.notifications = true;
    await openPlace(tester);

    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(guide.started.single.title, 'Colombo Fort');
    expect(find.text('Keep Hopin running'), findsOneWidget);
    expect(find.text('Turn on Autostart for Hopin'), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(guide.settingsOpened, 1);

    expect(find.text('Finding you'), findsOneWidget);
    expect(find.text('Where to?').hitTestable(), findsNothing);
    expect(boardColour(tester), HopinColors.light.board);

    guide.emit(
      const GuideUpdate(
        GuideStatus(metres: 2400, progress: 0.3, left: Duration(minutes: 6)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('2.4 km'), findsOneWidget);
    expect(find.text('6 min'), findsOneWidget);
    expect(find.text('Get off next'), findsNothing);

    guide.emit(
      const GuideUpdate(
        GuideStatus(
          metres: 380,
          progress: 0.9,
          left: Duration(seconds: 50),
          phase: GuidePhase.getOff,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Get off next'), findsOneWidget);
    expect(find.text('380 m'), findsOneWidget);
    expect(boardColour(tester), HopinColors.light.amber);

    await tester.tap(find.text('End'));
    await tester.pumpAndSettle();
    expect(guide.ends, 1);
    expect(find.text('Start'), findsOneWidget);
    expect(find.text('Where to?').hitTestable(), findsOneWidget);
    await finish(tester);
  });

  testWidgets('says "You passed your stop", and arriving ends the guide', (
    tester,
  ) async {
    guide.notifications = true;
    await openPlace(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    guide.emit(
      const GuideUpdate(
        GuideStatus(metres: 420, progress: 0.95, phase: GuidePhase.passed),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('You passed your stop'), findsOneWidget);
    expect(boardColour(tester), HopinColors.light.board);

    guide.emit(const GuideEnded(arrived: true));
    await tester.pumpAndSettle();
    expect(find.text("You've arrived"), findsOneWidget);
    expect(find.byType(RideBoard), findsNothing);
    expect(find.text('Start'), findsNothing);
    await finish(tester);
  });

  testWidgets('the first Start says why it wants notifications', (
    tester,
  ) async {
    await openPlace(tester);
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.textContaining('alerts you before your stop'), findsOneWidget);
    expect(guide.started, isEmpty);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(guide.notificationAsks, 1);
    expect(guide.started, hasLength(1));
    await finish(tester);
  });

  testWidgets('the ride board fits a small phone in Tamil with large text', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(1080, 2160)
      ..devicePixelRatio = 3;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await openPlace(tester, locale: const Locale('ta'));

    await tester.tap(find.text('தொடங்கு'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('தொடர்க'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('சரி'));
    await tester.pumpAndSettle();
    guide.emit(
      const GuideUpdate(
        GuideStatus(metres: 12400, progress: 0.2, left: Duration(minutes: 38)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12 கி.மீ'), findsOneWidget);
    expect(find.text('38 நிமி'), findsOneWidget);

    guide.emit(
      const GuideUpdate(
        GuideStatus(
          metres: 390,
          progress: 0.97,
          left: Duration(minutes: 1),
          phase: GuidePhase.getOff,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('அடுத்து இறங்குங்கள்'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await finish(tester);
  });
}
