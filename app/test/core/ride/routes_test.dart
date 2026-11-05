import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/routes.dart';

String file(String source, List<Map<String, Object?>> routes, {int? format}) =>
    jsonEncode({
      'format': format ?? routeFileFormat,
      'source': source,
      'built': '2026-11-05T00:00:00Z',
      'credit': 'x',
      'routes': routes,
    });

void main() {
  const a = GeoPoint(6.90, 79.85);
  const b = GeoPoint(6.93, 79.85);

  test('reads a route with its road, stops and times', () {
    final directions = parseRouteFile(
      file('lmt', [
        {
          'id': 'lmt:CM9',
          'number': 'CM9',
          'directions': [
            {
              'board': {'en': 'Beta', 'ta': 'பீட்டா'},
              'origin': {'en': 'Alpha'},
              'path': encodePolyline([a, b]),
              'stops': [
                [6.9, 79.85, 'One', 0],
                [6.93, 79.85],
              ],
              'times': [
                {
                  'days': 31,
                  'departs': [480, 420],
                },
              ],
            },
          ],
        },
      ]),
    );
    expect(directions, hasLength(1));
    final direction = directions.single;
    expect(direction.source, RouteSource.lmt);
    expect(direction.number, 'CM9');
    expect(direction.board, const PlaceNames(en: 'Beta', ta: 'பீட்டா'));
    expect(direction.origin, const PlaceNames(en: 'Alpha'));
    expect(direction.path, [a, b]);
    expect(direction.long, isFalse);
    expect(direction.stops, const [
      RouteStop(a, name: 'One', minutes: 0),
      RouteStop(b),
    ]);
    expect(direction.times.single.minutes, [420, 480]);
    // Monday to Friday.
    expect(direction.times.single.runsOn(DateTime(2026, 11, 6)), isTrue);
    expect(direction.times.single.runsOn(DateTime(2026, 11, 7)), isFalse);
  });

  test('reads the guessed rest of a partly mapped road', () {
    const c = GeoPoint(6.96, 79.85);
    final direction = parseRouteFile(
      file('osm', [
        {
          'id': 'osm:9',
          'number': '9',
          'directions': [
            {
              'board': {'en': 'North'},
              'path': encodePolyline([a, b]),
              'after': encodePolyline([b, c]),
            },
          ],
        },
      ]),
    ).single;
    expect(direction.path, [a, b]);
    expect(direction.after, [b, c]);
    expect(direction.before, isEmpty);
    // The whole road, joined once.
    expect(direction.road, [a, b, c]);
  });

  test('reads a long-distance route by its towns', () {
    final directions = parseRouteFile(
      file('ntc', [
        {
          'id': 'ntc:2:N',
          'number': '2',
          'also': ['2/1'],
          'classes': ['N', 'SL'],
          'long': true,
          'directions': [
            {
              'board': {'en': 'Beta'},
              'ends': [
                [6.9, 79.85],
                [6.93, 79.85],
              ],
              'stand': [6.901, 79.851, 'Central Bus Stand'],
              'times': [
                {
                  'days': 127,
                  'departs': [435],
                },
              ],
            },
            // No towns: it couldn't be matched at all.
            {
              'board': {'en': 'Alpha'},
            },
          ],
        },
      ]),
    );
    final direction = directions.single;
    expect(direction.long, isTrue);
    expect(direction.also, ['2/1']);
    expect(direction.classes, ['N', 'SL']);
    expect((direction.start, direction.end), (a, b));
    expect(
      direction.stand,
      const RouteStop(GeoPoint(6.901, 79.851), name: 'Central Bus Stand'),
    );
  });

  test('a direction without a board name or a number is left out', () {
    final directions = parseRouteFile(
      file('osm', [
        {
          'id': 'osm:1',
          'number': '1',
          'directions': [
            {
              'board': <String, Object?>{},
              'path': encodePolyline([a, b]),
            },
          ],
        },
        {
          'id': 'osm:2',
          'directions': [
            {
              'board': {'en': 'Beta'},
              'path': encodePolyline([a, b]),
            },
          ],
        },
      ]),
    );
    expect(directions, isEmpty);
  });

  test('a file of another format or source is refused', () {
    expect(
      () => parseRouteFile(file('osm', const [], format: 2)),
      throwsFormatException,
    );
    expect(() => parseRouteFile(file('bus', const [])), throwsFormatException);
    expect(() => parseRouteFile('<html>'), throwsFormatException);
  });

  test('route numbers compare loosely', () {
    expect(plainNumber('06'), plainNumber('6'));
    expect(plainNumber('15/87'), plainNumber('15-87'));
    expect(plainNumber('cm03'), 'CM03');
    expect(plainNumber('138/2'), isNot(plainNumber('138')));
  });

  group("the riders' notes", () {
    const north = RouteDirection(
      routeId: 'osm:9',
      source: RouteSource.osm,
      number: '9',
      board: PlaceNames(en: 'North', si: 'උතුර'),
      origin: PlaceNames(en: 'South'),
    );
    const south = RouteDirection(
      routeId: 'osm:9',
      source: RouteSource.osm,
      number: '9',
      board: PlaceNames(en: 'South'),
      origin: PlaceNames(en: 'North'),
    );
    final at = DateTime.utc(2026, 11, 5, 9);

    test('a direction is known to notes by its ends as the file has them', () {
      expect(north.noteKey, 'South>North');
      expect(
        const RouteDirection(
          routeId: 'ntc:1:N',
          source: RouteSource.ntc,
          number: '1',
          board: PlaceNames(ta: 'கண்டி'),
        ).noteKey,
        '>கண்டி',
      );
      // A rider's own board lines don't change it.
      expect(
        north.withBoard(const PlaceNames(en: 'Up')).noteKey,
        north.noteKey,
      );
    });

    test(
      'the newest note gives a direction its board lines, or removes it',
      () {
        final noted = withNotes(
          [north, south],
          [
            RouteNote(
              route: 'osm:9',
              direction: 'South>North',
              at: at,
              board: const PlaceNames(ta: 'வடக்கு'),
            ),
            RouteNote(
              route: 'osm:9',
              direction: 'South>North',
              at: at.subtract(const Duration(days: 1)),
              board: const PlaceNames(ta: 'old'),
              removed: true,
            ),
            RouteNote(
              route: 'osm:9',
              direction: 'North>South',
              at: at,
              removed: true,
            ),
            // Another route's.
            RouteNote(
              route: 'osm:10',
              direction: 'South>North',
              at: at,
              removed: true,
            ),
          ],
        );
        final [toNorth, toSouth] = noted;
        // The note's lines stand in for the file's; the others stay.
        expect(
          toNorth.direction.board,
          const PlaceNames(en: 'North', ta: 'வடக்கு', si: 'උතුර'),
        );
        expect((toNorth.edited, toNorth.removed), (true, false));
        expect(toNorth.file, north);
        expect((toSouth.edited, toSouth.removed), (false, true));
        expect(toSouth.direction, south);
      },
    );
  });
}
