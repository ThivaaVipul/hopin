import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/pooled_sync.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/route_files.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../helpers/fakes.dart';

/// A route file with one made-up route north from near Colombo Fort.
String routeFile(
  String source,
  String number, {
  int format = routeFileFormat,
}) => jsonEncode({
  'format': format,
  'source': source,
  'built': '2026-11-05T00:00:00Z',
  'credit': 'x',
  'routes': [
    {
      'id': '$source:$number',
      'number': number,
      'directions': [
        {
          'board': {'en': 'North'},
          'path': encodePolyline(const [
            GeoPoint(6.90, 79.85),
            GeoPoint(6.95, 79.85),
          ]),
        },
      ],
    },
  ],
});

void main() {
  late HopinDatabase db;
  late DateTime now;
  late RoutesRepository routes;

  setUp(() {
    db = memoryDatabase();
    now = DateTime.utc(2026, 11, 5, 8);
    routes = RoutesRepository(db, uid: 'r1', clock: () => now);
  });

  tearDown(() => db.close());

  Future<List<String>> numbers() async =>
      (await routes.watch().first).map((d) => d.number).toList();

  test('fetches each file once, and again a week later', () async {
    final asked = <http.Request>[];
    final files = routeFilesWith({
      'osm': routeFile('osm', '101'),
      'lmt': routeFile('lmt', 'CM9'),
    }, asked: asked);
    await routes.refresh(files);
    expect(asked.map((r) => r.url.pathSegments.last), [
      'osm-routes.json',
      'ntc-routes.json',
      'lmt-routes.json',
    ]);
    expect(await numbers(), unorderedEquals(['101', 'CM9']));
    // Hours on: nothing asked.
    now = now.add(const Duration(hours: 12));
    await routes.refresh(files);
    expect(asked, hasLength(3));
    // A day on: all of them, each with what the phone has.
    now = now.add(const Duration(hours: 12));
    await routes.refresh(files);
    expect(asked, hasLength(6));
    expect(asked[3].headers['If-None-Match'], '"osm-1"');
    // The file the release didn't have is asked for without one.
    expect(asked[4].headers.containsKey('If-None-Match'), isFalse);
  });

  test('an app update asks for every file at once', () async {
    final asked = <http.Request>[];
    final files = routeFilesWith({
      'osm': routeFile('osm', '101'),
    }, asked: asked);
    await RoutesRepository(
      db,
      uid: 'r1',
      clock: () => now,
      build: 10001,
    ).refresh(files);
    expect(asked, hasLength(3));
    await RoutesRepository(
      db,
      uid: 'r1',
      clock: () => now,
      build: 10001,
    ).refresh(files);
    expect(asked, hasLength(3));
    await RoutesRepository(
      db,
      uid: 'r1',
      clock: () => now,
      build: 10002,
    ).refresh(files);
    expect(asked, hasLength(6));
  });

  test('an unchanged file keeps what the phone has', () async {
    await routes.refresh(routeFilesWith({'osm': routeFile('osm', '101')}));
    now = now.add(const Duration(days: 8));
    final unchanged = RouteFiles(
      client: MockClient((_) async => http.Response('', 304)),
    );
    await routes.refresh(unchanged);
    expect(await numbers(), ['101']);
    final row = await (db.select(
      db.routeData,
    )..where((r) => r.source.equals('osm'))).getSingle();
    expect(row.checkedAt, now.microsecondsSinceEpoch);
  });

  test('a broken or newer file, or no network, keeps the old one', () async {
    await routes.refresh(routeFilesWith({'osm': routeFile('osm', '101')}));
    now = now.add(const Duration(days: 8));
    await routes.refresh(routeFilesWith({'osm': '<html>'}));
    expect(await numbers(), ['101']);
    await routes.refresh(
      routeFilesWith({'osm': routeFile('osm', '102', format: 2)}),
    );
    expect(await numbers(), ['101']);
    final offline = RouteFiles(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    await routes.refresh(offline);
    expect(await numbers(), ['101']);
  });

  test('a file this app can no longer read is left out', () async {
    await db
        .into(db.routeData)
        .insert(
          RouteDataCompanion.insert(source: 'osm', body: '{', checkedAt: 0),
        );
    expect(await numbers(), isEmpty);
  });

  group("the riders' notes", () {
    late FakeRemote remote;
    late RouteNotesSync sync;

    setUp(() async {
      remote = FakeRemote();
      sync = RouteNotesSync(db, remote);
      routes.onChange = sync.push;
      await routes.refresh(routeFilesWith({'osm': routeFile('osm', '9')}));
      await sync.start();
    });

    tearDown(() => sync.stop());

    test('board lines and a removal are shared notes', () async {
      final noted = (await routes.watchNoted().first).single;
      // The file's own English line is no change; Tamil is.
      await routes.setBoard(noted, const PlaceNames(en: 'North', ta: 'வடக்கு'));
      await pumpEventQueue();
      expect(
        (await routes.watch().first).single.board,
        const PlaceNames(en: 'North', ta: 'வடக்கு'),
      );
      final edit = remote.puts.last;
      expect(edit.$1, startsWith('routeNotes/'));
      expect(edit.$2, {
        'route': 'osm:9',
        'direction': '>North',
        'ta': 'வடக்கு',
        'si': null,
        'en': null,
        'removed': false,
        'by': 'r1',
      });

      now = now.add(const Duration(minutes: 1));
      await routes.setRemoved([
        (await routes.watchNoted().first).single,
      ], removed: true);
      await pumpEventQueue();
      expect(await routes.watch().first, isEmpty);
      final removed = (await routes.watchNoted().first).single;
      expect(removed.removed, isTrue);
      // Removing keeps the riders' lines, for when it's put back.
      expect(removed.direction.board.ta, 'வடக்கு');
      expect(remote.puts.last.$2['removed'], isTrue);
    });

    test("takes the other rider's notes", () async {
      remote.push('routeNotes', [
        RemoteDoc('n1', {
          'route': 'osm:9',
          'direction': '>North',
          'ta': 'வடக்கு',
          'removed': false,
          'by': 'r2',
        }, 5000000000),
      ]);
      await pumpEventQueue();
      expect((await routes.watch().first).single.board.ta, 'வடக்கு');
    });
  });

  group('routes added by hand', () {
    late FakeRemote remote;
    late HandRoutesSync sync;
    const fort = RouteTown(
      GeoPoint(6.9344, 79.8428),
      PlaceNames(en: 'Fort', ta: 'கோட்டை'),
    );
    const hall = RouteTown(GeoPoint(6.9150, 79.8600), PlaceNames(en: 'Hall'));
    const lake = RouteTown(GeoPoint(6.9000, 79.8700), PlaceNames(si: 'වැව'));
    const road = [
      GeoPoint(6.9344, 79.8428),
      GeoPoint(6.9150, 79.8600),
      GeoPoint(6.9000, 79.8700),
    ];

    setUp(() async {
      remote = FakeRemote();
      sync = HandRoutesSync(db, remote);
      routes.onChange = sync.push;
      await sync.start();
    });

    tearDown(() => sync.stop());

    test(
      'one runs both ways for both riders, and is deleted for both',
      () async {
        final kept = await routes.saveHand(
          const HandRoute(
            id: '',
            number: ' 138 ',
            from: fort,
            to: lake,
            via: [hall],
            road: road,
          ),
        );
        await pumpEventQueue();
        expect(kept.id, hasLength(20));
        expect(kept.number, '138');
        final both = await routes.watch().first;
        expect(both.map((d) => (d.number, d.source, d.board)), [
          ('138', RouteSource.hand, lake.names),
          ('138', RouteSource.hand, fort.names),
        ]);
        expect(both.first.path, road);
        expect(await routes.watchHand(kept.routeId).first, kept);

        final put = remote.puts.last;
        expect(put.$1, 'routes/${kept.id}');
        expect(put.$2, {
          'number': '138',
          'fromLat': 6.9344,
          'fromLng': 79.8428,
          'fromEn': 'Fort',
          'fromTa': 'கோட்டை',
          'fromSi': null,
          'toLat': 6.9,
          'toLng': 79.87,
          'toEn': null,
          'toTa': null,
          'toSi': 'වැව',
          'via': '[{"lat":6.915,"lng":79.86,"en":"Hall"}]',
          'road': encodePolyline(road),
          'by': 'r1',
        });
        expect(put.$3, isFalse);

        // Changed: the same route, now straight to the lake.
        now = now.add(const Duration(minutes: 1));
        await routes.saveHand(
          HandRoute(
            id: kept.id,
            number: '138',
            from: fort,
            to: lake,
            road: [road.first, road.last],
          ),
        );
        await pumpEventQueue();
        expect((await routes.watchHand(kept.routeId).first)?.via, isEmpty);
        expect(await routes.watch().first, hasLength(2));

        now = now.add(const Duration(minutes: 1));
        await routes.deleteHand(kept.id);
        await pumpEventQueue();
        expect(await routes.watch().first, isEmpty);
        expect(await routes.watchHand(kept.routeId).first, isNull);
        expect(remote.puts.last.$3, isTrue);
      },
    );

    test("takes the other rider's, and their deletes", () async {
      Map<String, Object?> doc({int? deletedAt}) => {
        'number': '177',
        'fromLat': 6.9344,
        'fromLng': 79.8428,
        'fromEn': 'Fort',
        'toLat': 6.9,
        'toLng': 79.87,
        'toEn': 'Lake',
        'via': '[]',
        'road': encodePolyline(road),
        'by': 'r2',
        'deletedAt': deletedAt,
      };
      remote.push('routes', [RemoteDoc('abc', doc(), 5000000000)]);
      await pumpEventQueue();
      expect((await routes.watch().first).map((d) => d.number), ['177', '177']);
      remote.push('routes', [
        RemoteDoc('abc', doc(deletedAt: 6000000000), 6000000000),
      ]);
      await pumpEventQueue();
      expect(await routes.watch().first, isEmpty);
    });

    test('a long road is thinned until the rules take it', () async {
      // About 120 km of wiggles a few metres wide, a point every 11 m.
      final long = [
        for (var i = 0; i < 11000; i++)
          GeoPoint(6.9 + i * 0.0001, 79.85 + (i.isEven ? 0 : 0.00003)),
      ];
      final kept = await routes.saveHand(
        HandRoute(id: '', number: '1', from: fort, to: lake, road: long),
      );
      await pumpEventQueue();
      final sent = remote.puts.last.$2['road']! as String;
      expect(sent.length, lessThanOrEqualTo(RoutesRepository.roadLetters));
      // Its ends stay where they were (to the polyline's 1 m or so).
      final back = (await routes.watchHand(kept.routeId).first)!.road;
      expect(back.first.distanceTo(long.first), lessThan(2));
      expect(back.last.distanceTo(long.last), lessThan(2));
    });
  });
}
