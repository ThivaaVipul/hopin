import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/share/share.dart';
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
  late FakeShares shares;
  late DateTime now;
  late List<Uri> lookups;

  setUp(() {
    workspace = Workspace('r1', memoryDatabase(), FakeRemote());
    location = FakeLocation(here: here);
    guide = FakeGuide();
    shares = FakeShares();
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
    shares: shares,
    overpass: emptyOverpass(),
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

  group('ride detection', () {
    final ride = RideRecord(
      id: 'ride1',
      startedAt: DateTime.utc(2026, 1, 1, 8),
      endedAt: DateTime.utc(2026, 1, 1, 8, 30),
      verdict: RideVerdict.bus,
      distanceM: 6000,
      features: const {'minutes': 30},
    );

    test('offers detection once, when location is there', () async {
      location.access = LocationAccess.granted;
      final home = cubit();
      await home.start();
      expect(home.state.offerDetection, isTrue);
      await home.detectionNotNow();
      expect(home.state.offerDetection, isFalse);
      await home.close();

      final again = cubit();
      await again.start();
      expect(again.state.offerDetection, isFalse);
      await again.close();
    });

    test('turning it on from the card', () async {
      location.access = LocationAccess.granted;
      final home = cubit();
      await home.start();
      await home.turnOnDetection('en');
      expect((await guide.detection()).on, isTrue);
      expect(home.state.offerDetection, isFalse);
      await home.close();
    });

    test('no card while detection is already on', () async {
      location.access = LocationAccess.granted;
      guide.detected = const Detection(
        on: true,
        activity: true,
        allTheTime: true,
      );
      final home = cubit();
      await home.start();
      expect(home.state.offerDetection, isFalse);
      await home.close();
    });

    test('shows the question, and sends the answer', () async {
      final home = cubit();
      await home.start();
      guide.emit(const RideQuestion());
      expect(home.state.question, isTrue);
      await home.answer('notbus');
      expect(guide.answers, ['notbus']);
      expect(home.state.question, isFalse);

      guide.emit(const RideQuestion());
      guide.emit(const RideAnswered());
      expect(home.state.question, isFalse);
      await home.close();
    });

    test('a place button starts ride mode', () async {
      final home = cubit();
      await home.start();
      guide.emit(const RideQuestion());
      const ride = GuideRide(
        to: GeoPoint(6.9344, 79.8501),
        title: 'Fort',
        names: PlaceNames(si: 'කොළඹ කොටුව'),
      );
      guide.emit(const GuideStarted(ride));
      expect(home.state.ride, ride);
      expect(home.state.question, isFalse);
      expect(home.state.destination?.point, ride.to);
      await home.close();
    });

    test('keeps rides, also those finished while Hopin was closed', () async {
      guide.pending.add(ride);
      final home = cubit();
      await home.start();
      await pumpEventQueue();
      expect((await workspace.rides.watch().first).single.id, 'ride1');
      expect(guide.forgotten, ['ride1']);

      final later = RideRecord(
        id: 'ride2',
        startedAt: DateTime.utc(2026, 1, 2, 8),
        endedAt: DateTime.utc(2026, 1, 2, 9),
        verdict: RideVerdict.notBus,
        distanceM: 900,
      );
      guide.emit(RideLogged(later));
      await pumpEventQueue();
      expect((await workspace.rides.watch().first).map((r) => r.id), [
        'ride2',
        'ride1',
      ]);
      await home.close();
    });
  });

  group('sharing', () {
    const fortRide = GuideRide(to: GeoPoint(6.9344, 79.8501), title: 'Fort');

    test(
      "Share starts the ride's share once and hands back its link",
      () async {
        guide.ride = fortRide;
        final home = cubit();
        await home.start();
        final link = await home.share();
        final id = guide.shared.single;
        expect(link, 'https://hopin-riders.web.app/r/$id');
        expect(home.state.sharing, id);

        expect(await home.share(), link);
        expect(guide.shared, hasLength(1));

        await home.stopSharing();
        expect(guide.sharing, isNull);
        expect(home.state.sharing, isNull);
        await home.close();
      },
    );

    test('a noticed ride shows its bar until it ends', () async {
      final home = cubit();
      await home.start();
      final since = DateTime.utc(2026, 1, 1, 7, 50);
      guide.emit(RideNoticed(since));
      expect(home.state.noticedSince, since);
      await home.share();
      expect(home.state.sharing, isNotNull);

      guide.emit(const GuideEnded(arrived: false));
      expect(home.state.noticedSince, isNull);
      expect(home.state.sharing, isNull);

      guide.emit(RideNoticed(since));
      await home.endRide();
      expect(guide.ends, 1);
      expect(home.state.noticedSince, isNull);
      await home.close();
    });

    test('a guide to a place shared by itself starts shared', () async {
      final shared = await workspace.places.add(
        const Destination(point: GeoPoint(6.9344, 79.8501)),
        name: 'Fort',
        kind: PlaceKind.other,
        shareRides: true,
      );
      location.access = LocationAccess.granted;
      guide.notifications = true;
      await workspace.settings.write(SettingsStore.batteryExplained, '1');
      final home = cubit();
      await home.start();
      home.select(Destination.fromSaved(shared));
      await home.startGuide(title: 'Fort', language: 'en');
      expect(guide.started.single.share, isTrue);
      await home.close();
    });

    LiveShare shareOf(
      String uid, {
      String id = 's1',
      Duration age = Duration.zero,
    }) => LiveShare(
      id: id,
      uid: uid,
      at: const GeoPoint(6.9101, 79.8523),
      goal: const ShareGoal(
        name: 'Fort',
        point: GeoPoint(6.9344, 79.8501),
        minutesLeft: 12,
      ),
      updatedAt: now.subtract(age),
    );

    test("the other rider's share: a card, Watch, then Not now", () async {
      final home = cubit();
      await home.start();
      shares.emit([shareOf('r1', id: 'mine'), shareOf('r2')]);
      expect(home.state.other?.id, 's1');

      home.watch();
      expect(home.state.watching, isTrue);
      home.closeWatch();
      expect(home.state.watching, isFalse);

      home.dismissShare();
      expect(home.state.other, isNull);
      shares.emit([shareOf('r2')]);
      expect(home.state.other, isNull);

      shares.emit([shareOf('r2', id: 's2')]);
      expect(home.state.other?.id, 's2');
      shares.emit([]);
      expect(home.state.other, isNull);
      await home.close();
    });

    test('leaves out a share gone quiet', () async {
      final home = cubit();
      await home.start();
      shares.emit([shareOf('r2', age: const Duration(minutes: 16))]);
      expect(home.state.other, isNull);
      await home.close();
    });

    test('ends a share the stopped service left open', () async {
      final home = cubit();
      await home.start();
      expect(shares.closedFor, ['r1']);
      await home.close();

      guide.watchingRide = true;
      final again = cubit();
      await again.start();
      expect(shares.closedFor, ['r1']);
      await again.close();
    });
  });

  group('stops', () {
    /// Two bus rides halting at the same synthetic spot: a learned stop.
    Future<void> twoBusRides() async {
      for (final id in ['ride1', 'ride2']) {
        await workspace.rides.save(
          RideRecord(
            id: id,
            startedAt: DateTime.utc(2026, 1, 1, 8),
            endedAt: DateTime.utc(2026, 1, 1, 8, 30),
            verdict: RideVerdict.bus,
            distanceM: 4000,
            path: const [GeoPoint(6.92, 79.85), GeoPoint(6.927, 79.851)],
            halts: const [Halt(GeoPoint(6.927, 79.851), 30)],
          ),
        );
      }
    }

    const sw = GeoPoint(6.90, 79.83);
    const ne = GeoPoint(6.95, 79.88);

    test('show at street level, and only those in view', () async {
      await twoBusRides();
      final home = cubit();
      await home.start();
      await pumpEventQueue();
      home.cameraIdle(sw, ne, 13);
      expect(home.state.stops, isEmpty);
      home.cameraIdle(sw, ne, 16);
      expect(home.state.stops.single.learned, isTrue);
      home.cameraIdle(
        const GeoPoint(7.0, 80.0),
        const GeoPoint(7.05, 80.05),
        16,
      );
      expect(home.state.stops, isEmpty);
      await home.close();
    });

    test("a tap opens the stop's panel, named at street level", () async {
      await twoBusRides();
      final home = cubit();
      await home.start();
      await pumpEventQueue();
      home.cameraIdle(sw, ne, 16);
      final stop = home.state.stops.single;
      await home.selectStop(stop.id, language: 'en');
      expect(home.state.stop?.id, stop.id);
      expect(home.state.destination?.point, stop.point);
      expect(home.state.destination?.names.en, 'Colombo Fort');
      expect(lookups.last.queryParameters['zoom'], '17');
      await home.close();
    });

    test('rename and remove a learned stop, for both riders', () async {
      await twoBusRides();
      final home = cubit();
      await home.start();
      await pumpEventQueue();
      home.cameraIdle(sw, ne, 16);
      await home.selectStop(home.state.stops.single.id, language: 'en');

      await home.renameStop('Lake gate');
      await pumpEventQueue();
      expect(home.state.destination?.names.en, 'Lake gate');
      expect(home.state.stops.single.names.en, 'Lake gate');

      await home.removeStop();
      await pumpEventQueue();
      expect(home.state.destination, isNull);
      expect(home.state.stop, isNull);
      expect(home.state.stops, isEmpty);
      await home.close();
    });

    test('another destination closes the stop panel', () async {
      await twoBusRides();
      final home = cubit();
      await home.start();
      await pumpEventQueue();
      home.cameraIdle(sw, ne, 16);
      await home.selectStop(home.state.stops.single.id, language: 'en');
      home.select(const Destination(point: GeoPoint(6.93, 79.86)));
      expect(home.state.stop, isNull);
      await home.close();
    });
  });
}
