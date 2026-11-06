import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/pooled_sync.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';

import '../../helpers/fakes.dart';

final bus = RideRecord(
  id: 'ride1',
  startedAt: DateTime.utc(2026, 1, 1, 8),
  endedAt: DateTime.utc(2026, 1, 1, 8, 30),
  verdict: RideVerdict.bus,
  distanceM: 6200,
  path: const [GeoPoint(6.9, 79.85), GeoPoint(6.93, 79.85)],
  halts: const [Halt(GeoPoint(6.91, 79.85), 30)],
  features: const {'minutes': 30, 'busHaltsPerKm': 1.6},
  guideTo: 'Colombo Fort',
);

void main() {
  late HopinDatabase db;
  late RidesRepository rides;
  late FakeRemote remote;
  late RidesSync sync;
  const collection = 'people/r1/rides';

  setUp(() {
    db = memoryDatabase();
    rides = RidesRepository(db);
    remote = FakeRemote();
    sync = RidesSync(db, remote, 'r1');
    rides.onChange = sync.push;
  });

  tearDown(() async {
    await sync.stop();
    await db.close();
  });

  test('keeps a ride and sends it up', () async {
    await sync.start();
    await rides.save(bus);
    await sync.push();
    expect((await rides.watch().first).single, bus);
    final (path, data, deleted) = remote.puts.single;
    expect(path, '$collection/ride1');
    expect(data['startedAt'], DateTime.utc(2026, 1, 1, 8).toLocal());
    expect(data['verdict'], 'bus');
    expect(data['path'], isA<String>());
    expect(data['features'], {'minutes': 30, 'busHaltsPerKm': 1.6});
    expect(data['guideTo'], 'Colombo Fort');
    expect(deleted, isFalse);
    final row = await db.select(db.rides).getSingle();
    expect(row.pendingSince, isNull);
  });

  test('a ride that was not a bus goes up without its path', () async {
    await sync.start();
    await rides.save(bus.withNames(from: 'Slave Island', to: 'Fort'));
    await rides.setVerdict('ride1', RideVerdict.notBus);
    await sync.push();
    final last = remote.puts.last.$2;
    expect(last['verdict'], 'not_bus');
    expect(last['path'], isNull);
    expect(last['halts'], isNull);
    expect(last['fromName'], isNull);
    expect(last['toName'], isNull);
    final kept = (await rides.watch().first).single;
    expect(kept.path, isEmpty);
    expect(kept.features, bus.features);
  });

  test('relabels without losing the path, unless Not a bus', () async {
    await rides.save(bus);
    await rides.setVerdict('ride1', RideVerdict.unknown);
    final unsure = (await rides.watch().first).single;
    expect(unsure.verdict, RideVerdict.unknown);
    expect(unsure.path, bus.path);
    expect(unsure.halts, hasLength(1));
  });

  test('names a ride once, and sends the names up', () async {
    await sync.start();
    await rides.save(bus);
    expect((await rides.unnamed()).single.id, 'ride1');

    await rides.setNames('ride1', from: 'Slave Island');
    expect((await rides.unnamed()).single.fromName, 'Slave Island');
    await rides.setNames('ride1', to: 'Fort');
    await sync.push();
    expect(await rides.unnamed(), isEmpty);
    final named = (await rides.watch().first).single;
    expect((named.fromName, named.toName), ('Slave Island', 'Fort'));
    expect(remote.puts.last.$2['fromName'], 'Slave Island');
    expect(remote.puts.last.$2['toName'], 'Fort');

    // The same names again change nothing.
    final sent = remote.puts.length;
    await rides.setNames('ride1', from: 'Slave Island', to: 'Fort');
    await sync.push();
    expect(remote.puts, hasLength(sent));
  });

  test('watches one ride until it is removed', () async {
    await rides.save(bus);
    final seen = <RideRecord?>[];
    final watching = rides.watchRide('ride1').listen(seen.add);
    await pumpEventQueue();
    await rides.setVerdict('ride1', RideVerdict.unknown);
    await pumpEventQueue();
    await rides.remove('ride1');
    await pumpEventQueue();
    await watching.cancel();
    expect(seen.map((r) => r?.verdict), [
      RideVerdict.bus,
      RideVerdict.unknown,
      null,
    ]);
  });

  test('removes by marking, newest first otherwise', () async {
    await sync.start();
    await rides.save(bus);
    final later = RideRecord(
      id: 'ride2',
      startedAt: DateTime.utc(2026, 1, 2, 8),
      endedAt: DateTime.utc(2026, 1, 2, 9),
      verdict: RideVerdict.unknown,
      distanceM: 1000,
    );
    await rides.save(later);
    expect((await rides.watch().first).map((r) => r.id), ['ride2', 'ride1']);

    await rides.remove('ride1');
    await sync.push();
    expect((await rides.watch().first).map((r) => r.id), ['ride2']);
    expect(remote.puts.last.$3, isTrue);
  });

  test("takes the server's rides", () async {
    await sync.start();
    remote.push(collection, [
      RemoteDoc('ride9', {
        'startedAt': DateTime.utc(2026, 1, 3, 7).microsecondsSinceEpoch,
        'endedAt': DateTime.utc(2026, 1, 3, 8).microsecondsSinceEpoch,
        'verdict': 'bus',
        'distanceM': 9000,
        'features': {'minutes': 60},
        'fromName': 'Fort',
      }, 5),
    ]);
    await pumpEventQueue();
    final ride = (await rides.watch().first).single;
    expect(ride.id, 'ride9');
    expect(ride.distanceM, 9000);
    expect(ride.features, {'minutes': 60});
  });

  group('the bus it was', () {
    const tag = RouteTag(
      route: 'osm:9',
      direction: 'South>North',
      number: '9',
      board: 'North',
    );
    late RouteRoadsSync roads;

    setUp(() async {
      rides = RidesRepository(db, uid: 'r1');
      roads = RouteRoadsSync(db, remote);
      rides.onChange = () {
        sync.push();
        roads.push();
      };
      await sync.start();
      await roads.start();
    });

    tearDown(() => roads.stop());

    List<(String, Map<String, Object?>, bool)> roadPuts() => [
      for (final put in remote.puts)
        if (put.$1.startsWith('routeRoads/')) put,
    ];

    test('a tagged bus ride goes up with its bus, its road shared', () async {
      await rides.save(bus.withRoute(tag));
      await pumpEventQueue();
      expect((await rides.watch().first).single.route, tag);
      final ride = remote.puts.firstWhere((p) => p.$1 == '$collection/ride1');
      expect(ride.$2['route'], tag.toJson());
      final (path, data, deleted) = roadPuts().single;
      expect(path, 'routeRoads/ride1');
      expect(data, {
        'uid': 'r1',
        'route': 'osm:9',
        'direction': 'South>North',
        'number': '9',
        'road': encodePolyline(bus.path),
      });
      expect(deleted, isFalse);
    });

    test(
      'tagged on its page; untagged, Not a bus or deleted, the road goes',
      () async {
        final unsure = bus.withVerdict(RideVerdict.unknown);
        await rides.save(unsure);
        await rides.setRoute('ride1', tag);
        await pumpEventQueue();
        // Tagging what Hopin was unsure of says it was a bus.
        final tagged = (await rides.watch().first).single;
        expect((tagged.route, tagged.verdict), (tag, RideVerdict.bus));
        expect(roadPuts().last.$3, isFalse);

        await rides.setRoute('ride1', null);
        await pumpEventQueue();
        expect(roadPuts().last.$3, isTrue);

        await rides.setRoute('ride1', tag);
        await rides.setVerdict('ride1', RideVerdict.notBus);
        await pumpEventQueue();
        expect((await rides.watch().first).single.route, isNull);
        expect(roadPuts().last.$3, isTrue);

        await rides.setVerdict('ride1', RideVerdict.bus);
        await rides.remove('ride1');
        await pumpEventQueue();
        expect(roadPuts().last.$3, isTrue);
      },
    );

    test("takes a ride's bus from the server", () async {
      remote.push(collection, [
        RemoteDoc('ride9', {
          'startedAt': DateTime.utc(2026, 1, 3, 7).microsecondsSinceEpoch,
          'endedAt': DateTime.utc(2026, 1, 3, 8).microsecondsSinceEpoch,
          'verdict': 'bus',
          'distanceM': 9000,
          'features': {'minutes': 60},
          'route': tag.toJson(),
        }, 5),
      ]);
      await pumpEventQueue();
      expect((await rides.watch().first).single.route, tag);
    });
  });
}
