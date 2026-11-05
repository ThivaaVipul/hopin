import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/pooled_sync.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/data/stops_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/overpass.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fakes.dart';
import '../search/nominatim_test.dart' show json;

/// Synthetic spots in Colombo, never real rides (CLAUDE.md).
const lakeRoad = GeoPoint(6.9270, 79.8510);
const clockTower = GeoPoint(6.9344, 79.8430);

RideRecord busRide(String id, {RideVerdict verdict = RideVerdict.bus}) =>
    RideRecord(
      id: id,
      startedAt: DateTime.utc(2026, 1, 1, 8),
      endedAt: DateTime.utc(2026, 1, 1, 8, 30),
      verdict: verdict,
      distanceM: 4000,
      path: const [GeoPoint(6.92, 79.85), lakeRoad],
      halts: const [
        Halt(lakeRoad, 30),
        // Too long for a stop (a jam, say): never pooled.
        Halt(GeoPoint(6.9300, 79.8505), 300),
      ],
    );

/// Overpass answering with one stop by the clock tower for any square.
Overpass fakeOverpass(List<http.Request> asked, {bool offline = false}) =>
    Overpass(
      client: MockClient((request) async {
        if (offline) throw http.ClientException('offline');
        asked.add(request);
        return json({
          'elements': [
            {
              'type': 'node',
              'id': 42,
              'lat': clockTower.lat,
              'lon': clockTower.lng,
              'tags': {
                'highway': 'bus_stop',
                'name': 'Clock Tower',
                'name:si': 'ඔරලෝසු කණුව',
              },
            },
            {'type': 'way', 'id': 7},
          ],
        });
      }),
      wait: (_) async {},
    );

void main() {
  late HopinDatabase db;
  late FakeRemote remote;
  late RidesRepository rides;
  late StopsRepository stops;
  late HaltsSync halts;
  late StopNotesSync notes;
  late DateTime now;

  setUp(() {
    db = memoryDatabase();
    remote = FakeRemote();
    now = DateTime.utc(2026, 1, 1, 9);
    rides = RidesRepository(db, uid: 'r1');
    stops = StopsRepository(db, uid: 'r1', clock: () => now);
    halts = HaltsSync(db, remote);
    notes = StopNotesSync(db, remote);
    rides.onChange = halts.push;
    stops.onChange = notes.push;
  });

  tearDown(() async {
    await halts.stop();
    await notes.stop();
    await db.close();
  });

  group('the pool of halts', () {
    test("a bus ride's stop-like halts go up; nothing else", () async {
      await halts.start();
      await rides.save(busRide('ride1'));
      await rides.save(busRide('ride2', verdict: RideVerdict.unknown));
      await pumpEventQueue();
      final put = remote.puts.single;
      expect(put.$1, 'halts/ride1');
      expect(put.$2, {'uid': 'r1', 'points': '6.92700,79.85100,30'});
      expect(put.$3, isFalse);
    });

    test('taken back when the ride is no longer a bus, or deleted', () async {
      await halts.start();
      await rides.save(busRide('ride1'));
      await rides.setVerdict('ride1', RideVerdict.notBus);
      await pumpEventQueue();
      expect(remote.puts.last.$2['points'], '');
      expect(remote.puts.last.$3, isTrue);

      await rides.save(busRide('ride2'));
      await rides.remove('ride2');
      await pumpEventQueue();
      expect(remote.puts.last.$1, 'halts/ride2');
      expect(remote.puts.last.$3, isTrue);
    });

    test('naming a ride sends nothing new to the pool', () async {
      await halts.start();
      await rides.save(busRide('ride1'));
      await pumpEventQueue();
      final sent = remote.puts.length;
      expect(sent, 1);
      await rides.setNames('ride1', from: 'Fort', to: 'Lake');
      await pumpEventQueue();
      expect(remote.puts, hasLength(sent));
    });

    test("takes the other rider's halts, and makes stops of both", () async {
      await halts.start();
      await rides.save(busRide('ride1'));
      expect(await stops.watch().first, isEmpty);

      remote.push('halts', [
        const RemoteDoc('their1', {
          'uid': 'r2',
          'points': '6.92702,79.85105,40',
          'deletedAt': null,
        }, 5000000000),
      ]);
      await pumpEventQueue();
      final stop = (await stops.watch().first).single;
      expect(stop.learned, isTrue);
      expect(stop.rides, 2);
    });
  });

  group('stops', () {
    Future<void> twoRides() async {
      await rides.save(busRide('ride1'));
      await rides.save(busRide('ride2'));
    }

    test('a rename and a removal are shared notes', () async {
      await notes.start();
      await twoRides();
      final stop = (await stops.watch().first).single;

      await stops.rename(stop, 'Lake gate');
      await pumpEventQueue();
      expect((await stops.watch().first).single.names.en, 'Lake gate');
      final rename = remote.puts.last;
      expect(rename.$1, startsWith('stopNotes/'));
      expect(rename.$2['name'], 'Lake gate');
      expect(rename.$2['removed'], isFalse);
      expect(rename.$2['by'], 'r1');

      now = now.add(const Duration(minutes: 1));
      await stops.remove(stop);
      await pumpEventQueue();
      expect(await stops.watch().first, isEmpty);
      expect(remote.puts.last.$2['removed'], isTrue);
    });

    test("takes the other rider's notes", () async {
      await notes.start();
      await twoRides();
      remote.push('stopNotes', [
        RemoteDoc('n1', {
          'lat': lakeRoad.lat,
          'lng': lakeRoad.lng,
          'name': 'Lake gate',
          'removed': false,
          'by': 'r2',
        }, 5000000000),
      ]);
      await pumpEventQueue();
      expect((await stops.watch().first).single.names.en, 'Lake gate');
    });

    test("a learned stop's name is looked up once, at street level", () async {
      await twoRides();
      final stop = (await stops.watch().first).single;
      final lookups = <Uri>[];
      final nominatim = fakeNominatim((request) async {
        lookups.add(request.url);
        return json({
          'lat': '${lakeRoad.lat}',
          'lon': '${lakeRoad.lng}',
          'name': 'Lake Road',
          'address': {'suburb': 'Slave Island'},
        });
      });
      expect(await stops.nameOf(stop, nominatim, language: 'en'), 'Lake Road');
      expect(lookups.single.queryParameters['zoom'], '17');
      expect((await stops.watch().first).single.names.en, 'Lake Road');
      expect(await stops.nameOf(stop, nominatim, language: 'en'), 'Lake Road');
      expect(lookups, hasLength(1));
    });

    test("OSM's stops come by square, once a month", () async {
      final asked = <http.Request>[];
      await stops.ensureAround([clockTower, clockTower], fakeOverpass(asked));
      expect(asked, hasLength(1));
      expect(asked.single.headers['User-Agent'], contains('Hopin'));
      final data = Uri.splitQueryString(asked.single.body)['data']!;
      expect(data, contains('"highway"="bus_stop"'));
      expect(data, contains('6.9000,79.8000,6.9500,79.8500'));

      final osm = (await stops.watch().first).single;
      expect(osm.id, 'osm:42');
      expect(osm.names.en, 'Clock Tower');
      expect(osm.names.si, 'ඔරලෝසු කණුව');

      await stops.ensureAround([clockTower], fakeOverpass(asked));
      expect(asked, hasLength(1));
      now = now.add(const Duration(days: 31));
      await stops.ensureAround([clockTower], fakeOverpass(asked));
      expect(asked, hasLength(2));
    });

    test('offline, a square waits for the next time', () async {
      final asked = <http.Request>[];
      await stops.ensureAround([
        clockTower,
      ], fakeOverpass(asked, offline: true));
      expect(await stops.watch().first, isEmpty);
      await stops.ensureAround([clockTower], fakeOverpass(asked));
      expect(asked, hasLength(1));
    });
  });

  test('a square holds about 5.5 km', () {
    final tile = StopTile.at(clockTower);
    expect(tile.key, '138/1596');
    expect((tile.south, tile.west), (6.9, 79.8));
    expect(StopTile.at(const GeoPoint(-0.01, -0.01)).key, '-1/-1');
    expect(jsonEncode(osmStopFrom({'type': 'way', 'id': 7})), 'null');
  });
}
