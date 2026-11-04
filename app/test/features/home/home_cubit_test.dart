import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/features/home/cubit/home_cubit.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fakes.dart';

const here = GeoPoint(6.9200, 79.8550);
const uni = Destination(
  point: GeoPoint(6.9344, 79.8501),
  names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
);

void main() {
  late Workspace workspace;
  late FakeLocation location;
  late FakeGuide guide;
  late DateTime now;
  late List<Uri> lookups;

  setUp(() {
    workspace = Workspace('r1', memoryDatabase(), FakeRemote());
    location = FakeLocation(here: here);
    guide = FakeGuide();
    now = DateTime.utc(2026, 1, 1, 8);
    lookups = [];
  });

  tearDown(() => workspace.close());

  HomeCubit cubit({List<Object>? reverse}) => HomeCubit(
    workspace,
    location,
    fakeNominatim((request) async {
      lookups.add(request.url);
      return http.Response.bytes(
        utf8.encode(
          jsonEncode(
            reverse ??
                {
                  'lat': '6.9344',
                  'lon': '79.8501',
                  'namedetails': {
                    'name:en': 'Colombo Fort',
                    'name:si': 'කොළඹ කොටුව',
                  },
                },
          ),
        ),
        200,
      );
    }),
    guide,
    clock: () => now,
  );

  /// Home with location allowed and [uni] open.
  Future<HomeCubit> atUni() async {
    location.access = LocationAccess.granted;
    final home = cubit();
    await home.start();
    home.select(uni);
    return home;
  }

  test('explains once, then asks, then follows you', () async {
    final home = cubit();
    await home.start();
    expect(home.state.location, LocationStatus.explain);

    await home.continueToPermission();
    expect(location.requests, 1);
    expect(home.state.location, LocationStatus.granted);
    expect(home.state.me, here);

    location.move(const GeoPoint(6.92, 79.86));
    expect(home.state.me, const GeoPoint(6.92, 79.86));
    await home.close();
  });

  test(
    '"Not now" is remembered, and location can be asked for later',
    () async {
      final first = cubit();
      await first.start();
      await first.notNow();
      expect(first.state.location, LocationStatus.denied);
      await first.close();

      final again = cubit();
      await again.start();
      expect(again.state.location, LocationStatus.denied);
      expect(location.requests, 0);

      await again.askForLocation();
      expect(again.state.location, LocationStatus.granted);
      await again.close();
    },
  );

  test(
    'starts following straight away when location is already allowed',
    () async {
      location.access = LocationAccess.granted;
      final home = cubit();
      await home.start();
      expect(home.state.location, LocationStatus.granted);
      expect(home.state.me, here);
      await home.close();
    },
  );

  test('opens a searched place and keeps it among the recents', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    expect(home.state.destination, uni);
    await pumpEventQueue();
    expect(
      (await workspace.recents.watch().first).single.names.si,
      'කොළඹ කොටුව',
    );
    await home.close();
  });

  test('names a dropped pin after the nearest place', () async {
    final home = cubit();
    await home.start();
    final pin = home.dropPin(const GeoPoint(6.9342, 79.8499));
    expect(home.state.resolving, isTrue);
    await pin;
    expect(home.state.resolving, isFalse);
    expect(home.state.destination?.names.si, 'කොළඹ කොටුව');
    expect(home.state.destination?.point, const GeoPoint(6.9342, 79.8499));
    await home.close();
  });

  test('saves the open place, renames it and removes it', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    await home.save(name: 'Uni', kind: PlaceKind.uni);
    await pumpEventQueue();
    final saved = home.state.destination!.saved!;
    expect(saved.name, 'Uni');
    expect(home.state.places.single.kind, PlaceKind.uni);

    await home.save(name: 'Campus', kind: PlaceKind.uni);
    await pumpEventQueue();
    expect(home.state.places.single.name, 'Campus');
    expect(home.state.destination!.saved!.name, 'Campus');

    await home.removePlace(home.state.places.single);
    await pumpEventQueue();
    expect(home.state.places, isEmpty);
    expect(home.state.destination!.saved, isNull);
    await home.close();
  });

  test('recognises a saved place when it is picked again', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    await home.save(name: 'Uni', kind: PlaceKind.uni);
    await pumpEventQueue();
    home
      ..clear()
      ..select(const Destination(point: GeoPoint(6.93441, 79.85011)));
    expect(home.state.destination!.saved?.name, 'Uni');
    await home.close();
  });

  group('the guide', () {
    test(
      'the first Start says why, asks for notifications, then guides',
      () async {
        final home = await atUni();
        await home.startGuide(title: 'Colombo Fort', language: 'en');
        expect(home.state.explainNotifications, isTrue);
        expect(guide.started, isEmpty);

        await home.continueToNotifications();
        expect(guide.notificationAsks, 1);
        expect(guide.backgroundAsks, 1);
        expect(guide.started.single.title, 'Colombo Fort');
        expect(guide.started.single.names.si, 'කොළඹ කොටුව');
        expect(guide.started.single.to, uni.point);
        expect(home.state.ride, guide.started.single);
        expect(home.state.explainNotifications, isFalse);
        expect(home.state.makerSteps, PhoneMaker.xiaomi);

        home.makerStepsSeen();
        expect(home.state.makerSteps, isNull);
        await home.close();
      },
    );

    test('later Starts go straight to the guide', () async {
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      await home.skipNotifications();
      expect(guide.notificationAsks, 0);
      expect(home.state.ride, isNotNull);
      home.makerStepsSeen();

      await home.endGuide();
      await home.startGuide(title: 'Colombo Fort', language: 'ta');
      expect(home.state.explainNotifications, isFalse);
      expect(guide.started, hasLength(2));
      expect(guide.started.last.language, 'ta');
      expect(guide.backgroundAsks, 1);
      expect(home.state.makerSteps, isNull);
      await home.close();
    });

    test('no card when notifications are already allowed', () async {
      guide
        ..notifications = true
        ..phoneMaker = PhoneMaker.other;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      expect(home.state.explainNotifications, isFalse);
      expect(home.state.ride, isNotNull);
      expect(home.state.makerSteps, isNull);
      await home.close();
    });

    test('says so when Android will not start the guide', () async {
      guide
        ..notifications = true
        ..startWorks = false;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      expect(home.state.ride, isNull);
      expect(home.state.notice, HomeNotice.guideFailed);
      home.noticed();
      expect(home.state.notice, isNull);
      await home.close();
    });

    test('asks for location first, and says so when refused', () async {
      location.afterRequest = LocationAccess.denied;
      final home = cubit();
      await home.start();
      home.select(uni);
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      expect(location.requests, 1);
      expect(guide.started, isEmpty);
      expect(home.state.notice, HomeNotice.needsLocation);
      await home.close();
    });

    test('shows the news, and looks up "Now near" once a minute', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      const status = GuideStatus(
        metres: 1800,
        progress: 0.4,
        left: Duration(minutes: 4),
        at: GeoPoint(6.92, 79.85),
      );
      guide.emit(const GuideUpdate(status));
      expect(home.state.status, status);
      await pumpEventQueue();
      expect(home.state.near?.names.en, 'Colombo Fort');
      expect(lookups.single.queryParameters['zoom'], '14');

      now = now.add(const Duration(seconds: 30));
      guide.emit(const GuideUpdate(status));
      await pumpEventQueue();
      expect(lookups, hasLength(1));

      now = now.add(const Duration(seconds: 31));
      guide.emit(
        const GuideUpdate(
          GuideStatus(metres: 900, progress: 0.7, at: GeoPoint(6.93, 79.85)),
        ),
      );
      await pumpEventQueue();
      expect(lookups, hasLength(2));
      await home.close();
    });

    test('arriving ends ride mode and leaves the place', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      guide.emit(const GuideEnded(arrived: true));
      expect(home.state.ride, isNull);
      expect(home.state.destination, isNull);
      expect(home.state.notice, HomeNotice.arrived);
      await home.close();
    });

    test('End, here or in the notification, goes back to the place', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      await home.endGuide();
      expect(guide.ends, 1);
      expect(home.state.ride, isNull);
      expect(home.state.destination?.point, uni.point);

      await home.startGuide(title: 'Colombo Fort', language: 'en');
      guide.emit(const GuideEnded(arrived: false));
      expect(home.state.ride, isNull);
      expect(home.state.destination?.point, uni.point);
      expect(home.state.notice, isNull);
      await home.close();
    });

    test('a running guide comes back when Home opens', () async {
      guide.ride = const GuideRide(
        to: GeoPoint(6.9344, 79.8501),
        title: 'Colombo Fort',
        names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
      );
      final home = cubit();
      await home.start();
      expect(home.state.ride, guide.ride);
      expect(home.state.destination?.names.si, 'කොළඹ කොටුව');
      await home.close();
    });

    test('ride mode keeps its stop', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      home
        ..select(const Destination(point: GeoPoint(6.9, 79.86)))
        ..clear();
      await home.dropPin(const GeoPoint(6.91, 79.87));
      expect(home.state.destination?.point, uni.point);
      expect(home.state.ride, isNotNull);
      await home.close();
    });

    test('a guide that gives up says so, and keeps the place', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      guide.emit(const GuideEnded(arrived: false, gaveUp: true));
      expect(home.state.ride, isNull);
      expect(home.state.destination?.point, uni.point);
      expect(home.state.notice, HomeNotice.gaveUp);
      await home.close();
    });

    test('Keep on the board reaches the guide', () async {
      guide.notifications = true;
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      await home.keepGoing();
      expect(guide.keeps, 1);
      await home.close();
    });

    test('the guide takes your own stages', () async {
      guide.notifications = true;
      await workspace.appSettings.setStages(const [
        GuideStage(700, AlertPattern.heartbeat),
      ]);
      final home = await atUni();
      await home.startGuide(title: 'Colombo Fort', language: 'en');
      expect(guide.started.single.stages, const [
        GuideStage(700, AlertPattern.heartbeat),
      ]);
      await home.close();
    });
  });
}
