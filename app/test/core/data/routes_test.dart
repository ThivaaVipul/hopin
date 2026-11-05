import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/geo/geo.dart';
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
    routes = RoutesRepository(db, clock: () => now);
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
    // A day on: only the file the release didn't have.
    now = now.add(const Duration(hours: 12));
    await routes.refresh(files);
    expect(asked.skip(3).map((r) => r.url.pathSegments.last), [
      'ntc-routes.json',
    ]);
    // A week on: all of them, each with what the phone has.
    now = now.add(const Duration(days: 7));
    await routes.refresh(files);
    expect(asked, hasLength(7));
    expect(asked[4].headers['If-None-Match'], '"osm-1"');
    expect(asked[5].headers.containsKey('If-None-Match'), isFalse);
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
}
