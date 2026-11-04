import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/app.dart';
import 'package:hopin/app/theme.dart';
import 'package:hopin/app/widgets/board_choice.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/share/share.dart';
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/home/widgets/ride_board.dart';
import 'package:http/http.dart' as http;

import '../core/data/ride_namer_test.dart' show slaveIslandJson;
import '../core/search/nominatim_test.dart' show json, uniJson;
import '../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeProfiles profiles;
  late FakeRemote remote;
  late FakeGuide guide;
  late FakeUpdates updates;
  late FakeShares shares;
  late List<String> sent;

  setUp(() {
    auth = FakeAuth();
    profiles = FakeProfiles();
    remote = FakeRemote();
    guide = FakeGuide();
    updates = FakeUpdates();
    shares = FakeShares();
    sent = [];
  });

  Future<void> start(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    LocationService? location,
    Future<http.Response> Function(http.Request request)? nominatim,
  }) async {
    await tester.pumpWidget(
      HopinApp(
        auth: auth,
        profiles: profiles,
        remote: remote,
        openDatabase: memoryDatabase,
        location: location ?? FakeLocation(),
        nominatim: fakeNominatim(
          nominatim ??
              (_) async =>
                  http.Response.bytes(utf8.encode(jsonEncode([uniJson])), 200),
        ),
        mapBuilder: fakeMap,
        rideMapBuilder: fakeRideMap,
        guide: guide,
        shares: shares,
        shareSheet: (text) async => sent.add(text),
        updates: updates,
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

  /// Scrolls the Settings page until [finder] shows.
  Future<void> showInSettings(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> openAccount(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Settings'));
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

    await showInSettings(tester, find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(guide.ends, 1, reason: 'signing out ends a running guide');
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

  group('settings', () {
    Future<void> openSettings(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      await start(
        tester,
        locale: locale,
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byTooltip(locale.languageCode == 'ta' ? 'அமைப்புகள்' : 'Settings'),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('switches the whole app to Tamil and keeps the choice', (
      tester,
    ) async {
      await openSettings(tester);
      expect(find.text('Rider access is on'), findsOneWidget);

      await showInSettings(tester, find.text('தமிழ்'));
      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();
      expect(find.text('அமைப்புகள்'), findsOneWidget);
      expect(
        remote.puts.where((put) => put.$1 == 'people/r1/settings/app'),
        isNotEmpty,
      );
      expect(
        remote.puts.last.$2['language'],
        'ta',
        reason: 'the choice follows the account',
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('எங்கே போக வேண்டும்?'), findsOneWidget);
      expect(profiles.saved.last, ('r1', 'ta'));
      await finish(tester);
    });

    testWidgets('edits a stage, trying a pattern first', (tester) async {
      await openSettings(tester);
      await showInSettings(tester, find.text('Get off next'));
      expect(find.text('400 m'), findsOneWidget);

      await tester.tap(find.text('Get off next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('700 m'));
      await tester.pump();
      await tester.tap(find.text('Try').at(2));
      expect(guide.played.single.length, greaterThan(Duration.zero));
      await tester.tap(find.text('Heartbeat'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('700 m'), findsOneWidget);
      expect(find.text('Heartbeat'), findsOneWidget);
      expect(find.text('400 m'), findsNothing);
      await finish(tester);
    });

    testWidgets('adds a third stage, and no more', (tester) async {
      await openSettings(tester);
      await showInSettings(tester, find.text('Add a stage'));
      await tester.tap(find.text('Add a stage'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(find.text('3 km'), findsOneWidget);
      expect(find.text('Get ready'), findsNWidgets(2));
      expect(find.text('Add a stage'), findsNothing);
      await finish(tester);
    });

    testWidgets('fits a small phone in Tamil with large text', (tester) async {
      tester.view
        ..physicalSize = const Size(1080, 2160)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      guide.notifications = false;
      await openSettings(tester, locale: const Locale('ta'));
      await showInSettings(tester, find.text('வெளியேறு'));
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });

  group('updates', () {
    testWidgets('offers a newer version and opens the installer', (
      tester,
    ) async {
      updates
        ..installed = 3000
        ..release = Release(
          build: 4000,
          apk: Uri.parse('https://example.com/hopin-0.4.0.apk'),
          size: 35000000,
        );
      await start(
        tester,
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      expect(find.text('Hopin 0.4.0 is ready'), findsOneWidget);

      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();
      expect(updates.downloads, 1);
      expect(updates.installs.single, endsWith('hopin-0.4.0.apk'));
      await finish(tester);
    });

    testWidgets('a test build shows no banner and no Check', (tester) async {
      updates.release = Release(
        build: 4000,
        apk: Uri.parse('https://example.com/hopin-0.4.0.apk'),
        size: 1,
      );
      await start(
        tester,
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      expect(updates.checks, 0);
      expect(find.text('Hopin 0.4.0 is ready'), findsNothing);
      await openAccount(tester);
      await showInSettings(tester, find.text('Test build'));
      expect(find.text('Check'), findsNothing);
      await finish(tester);
    });
  });

  group('ride detection', () {
    testWidgets('offers to notice bus rides, then asks "On a bus?"', (
      tester,
    ) async {
      await start(
        tester,
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      expect(find.textContaining('notice your bus rides'), findsOneWidget);

      await tester.tap(find.text('Turn on'));
      await tester.pumpAndSettle();
      expect((await guide.detection()).on, isTrue);
      expect(find.textContaining('notice your bus rides'), findsNothing);

      guide.emit(const RideQuestion());
      await tester.pumpAndSettle();
      expect(find.text('On a bus?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      await tester.tap(find.text('Not a bus'));
      await tester.pumpAndSettle();
      expect(guide.answers, ['notbus']);
      expect(find.text('On a bus?'), findsNothing);
      await finish(tester);
    });

    testWidgets('the cards fit a small phone in Tamil with large text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2160)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await start(
        tester,
        locale: const Locale('ta'),
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      expect(find.text('இயக்கு'), findsOneWidget);
      guide.emit(const RideQuestion());
      await tester.pumpAndSettle();
      expect(find.text('பஸ் அல்ல'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });

  group('rides', () {
    /// This morning's bus ride, with its path and a halt, and yesterday's
    /// unanswered one without a path.
    void logRides() {
      final today = DateTime.now();
      final morning = DateTime(today.year, today.month, today.day, 8, 10);
      guide.pending.addAll([
        RideRecord(
          id: 'ride1',
          startedAt: morning.toUtc(),
          endedAt: morning.add(const Duration(minutes: 24)).toUtc(),
          verdict: RideVerdict.bus,
          distanceM: 2400,
          path: const [GeoPoint(6.9270, 79.8510), GeoPoint(6.9344, 79.8501)],
          halts: const [Halt(GeoPoint(6.9300, 79.8505), 30)],
        ),
        RideRecord(
          id: 'ride2',
          startedAt: morning.subtract(const Duration(hours: 15)).toUtc(),
          endedAt: morning.subtract(const Duration(hours: 14)).toUtc(),
          verdict: RideVerdict.unknown,
          distanceM: 850,
        ),
      ]);
    }

    /// Lets the namer's lookups finish: the database's streams complete on
    /// the real event loop, which the test's fake clock doesn't drive.
    Future<void> namesFound(WidgetTester tester) async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 300)),
      );
      await tester.pumpAndSettle();
    }

    /// Whether the ride's label [label] is the chosen one.
    bool chosen(WidgetTester tester, String label) => tester
        .widget<BoardChoice>(find.widgetWithText(BoardChoice, label))
        .selected;

    /// Reverse lookups name Slave Island (south) or the Fort (north).
    Future<http.Response> places(http.Request request) async {
      if (request.url.path != '/reverse') return json([uniJson]);
      final lat = double.parse(request.url.queryParameters['lat']!);
      return json(lat < 6.93 ? slaveIslandJson : uniJson);
    }

    testWidgets('lists rides by day; one opens, relabels and deletes', (
      tester,
    ) async {
      logRides();
      await start(
        tester,
        location: FakeLocation(access: LocationAccess.granted),
        nominatim: places,
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      await openAccount(tester);
      await showInSettings(tester, find.text('All rides'));
      await tester.tap(find.text('All rides'));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('8:10 AM'), findsOneWidget);
      await namesFound(tester);
      expect(find.textContaining('Slave Island'), findsOneWidget);
      expect(find.textContaining('Colombo Fort'), findsOneWidget);
      expect(find.text('24 min'), findsOneWidget);
      expect(find.text('2.4 km'), findsOneWidget);
      expect(find.text('Bus'), findsOneWidget);
      expect(find.text('Unsure'), findsOneWidget);
      expect(find.text('850 m'), findsOneWidget);

      await tester.tap(find.text('8:10 AM'));
      await tester.pumpAndSettle();
      expect(find.text('ride map: 2 points, 1 halts'), findsOneWidget);
      expect(find.text('8:10 AM - 8:34 AM'), findsOneWidget);
      expect(chosen(tester, 'Bus'), isTrue);

      // Not a bus keeps no path: asked first.
      await tester.tap(find.text('Not a bus'));
      await tester.pumpAndSettle();
      expect(find.text('Not a bus keeps no path. Remove it?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('ride map: 2 points, 1 halts'), findsOneWidget);
      await tester.tap(find.text('Not a bus'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Remove'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ride map'), findsNothing);
      expect(chosen(tester, 'Not a bus'), isTrue);

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete this ride?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(find.text('Today'), findsNothing);
      expect(find.text('Yesterday'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('the rides pages fit a small phone in Tamil with large text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2160)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      logRides();
      await start(
        tester,
        locale: const Locale('ta'),
        location: FakeLocation(access: LocationAccess.granted),
        nominatim: places,
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('அமைப்புகள்'));
      await tester.pumpAndSettle();
      await showInSettings(tester, find.text('எல்லாப் பயணங்களும்'));
      await tester.tap(find.text('எல்லாப் பயணங்களும்'));
      await tester.pumpAndSettle();
      await namesFound(tester);
      expect(find.text('இன்று'), findsOneWidget);
      expect(find.textContaining('Slave Island'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.textContaining('Slave Island'));
      await tester.pumpAndSettle();
      expect(find.text('தெரியாது'), findsOneWidget);
      expect(find.text('பஸ் அல்ல'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });

  group('sharing', () {
    const fortRide = GuideRide(
      to: GeoPoint(6.9344, 79.8501),
      title: 'Colombo Fort',
    );

    LiveShare theirs() => LiveShare(
      id: 's1',
      uid: 'r2',
      at: const GeoPoint(6.9101, 79.8523),
      goal: const ShareGoal(
        name: 'Colombo Fort',
        nameTa: 'கொழும்பு கோட்டை',
        point: GeoPoint(6.9344, 79.8501),
        minutesLeft: 12,
      ),
      updatedAt: DateTime.now(),
    );

    Future<void> signedIn(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      await start(
        tester,
        locale: locale,
        location: FakeLocation(access: LocationAccess.granted),
      );
      auth.emit(rider);
      await tester.pumpAndSettle();
    }

    testWidgets('Share on the ride board sends the link, then can stop', (
      tester,
    ) async {
      guide.ride = fortRide;
      await signedIn(tester);
      expect(find.byType(RideBoard), findsOneWidget);

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      final id = guide.shared.single;
      expect(sent, [
        'Follow my bus ride live: https://hopin-riders.web.app/r/$id',
      ]);

      await tester.tap(find.byTooltip('Sharing this ride'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();
      expect(sent, hasLength(2));
      expect(guide.shared, hasLength(1));

      await tester.tap(find.byTooltip('Sharing this ride'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop sharing'));
      await tester.pumpAndSettle();
      expect(guide.sharing, isNull);
      expect(find.byTooltip('Share'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('a noticed ride shows its bar, with Share and End', (
      tester,
    ) async {
      await signedIn(tester);
      guide.emit(
        RideNoticed(DateTime.now().subtract(const Duration(minutes: 12))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('On a bus'), findsOneWidget);
      expect(find.textContaining('12 min'), findsOneWidget);

      await tester.tap(find.byTooltip('Share'));
      await tester.pumpAndSettle();
      expect(sent, hasLength(1));

      await tester.tap(find.text('End'));
      await tester.pumpAndSettle();
      expect(guide.ends, 1);
      expect(find.textContaining('On a bus'), findsNothing);
      await finish(tester);
    });

    testWidgets("the other rider's share: a card, Watch, then Not now", (
      tester,
    ) async {
      await signedIn(tester);
      shares.emit([theirs()]);
      await tester.pumpAndSettle();
      expect(find.text('Shared ride to Colombo Fort'), findsOneWidget);
      expect(find.text('12 min'), findsOneWidget);

      await tester.tap(find.text('Watch'));
      await tester.pumpAndSettle();
      expect(find.text('Updated just now'), findsOneWidget);
      expect(find.textContaining('watching'), findsOneWidget);

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(find.textContaining('watching'), findsNothing);
      await tester.tap(find.text('Not now').first);
      await tester.pumpAndSettle();
      expect(find.text('Shared ride to Colombo Fort'), findsNothing);
      await finish(tester);
    });

    testWidgets('a place can share rides there', (tester) async {
      await openPlace(tester);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save').last);
      await tester.pumpAndSettle();
      final place = remote.puts.lastWhere(
        (put) => put.$1.startsWith('people/r1/places/'),
      );
      expect(place.$2['shareRides'], isTrue);
      await finish(tester);
    });

    testWidgets('sharing fits a small phone in Tamil with large text', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(1080, 2160)
        ..devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await signedIn(tester, locale: const Locale('ta'));

      shares.emit([theirs()]);
      await tester.pumpAndSettle();
      expect(
        find.text('கொழும்பு கோட்டை நோக்கிப் பகிர்ந்த பயணம்'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('பார்'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('மூடு'));
      await tester.pumpAndSettle();

      guide.emit(
        RideNoticed(DateTime.now().subtract(const Duration(minutes: 5))),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('பஸ் பயணம்'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });
  });
}
