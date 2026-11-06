import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/ride/which_bus.dart';

/// A straight road north from just south of Colombo Fort.
const _road = [
  GeoPoint(6.90, 79.85),
  GeoPoint(6.95, 79.85),
  GeoPoint(7.00, 79.85),
];

const north = RouteDirection(
  routeId: 'osm:9',
  source: RouteSource.osm,
  number: '9',
  board: PlaceNames(en: 'North', ta: 'வடக்கு'),
  origin: PlaceNames(en: 'South'),
  path: _road,
);

void main() {
  test('a tag names the bus by its route, direction, number and board', () {
    final tag = RouteTag.of(north, language: 'ta');
    expect(
      tag,
      const RouteTag(
        route: 'osm:9',
        direction: 'South>North',
        number: '9',
        board: 'வடக்கு',
      ),
    );
    expect(tag.matches(north), isTrue);
    expect(RouteTag.fromJson(tag.toJson()), tag);
    expect(RouteTag.fromJson({'id': 'osm:9'}), isNull);
  });

  test('a ride and a guide carry their tag, and Not a bus drops it', () {
    final tag = RouteTag.of(north, language: 'en');
    final ride = RideRecord(
      id: 'r1',
      startedAt: DateTime.utc(2026, 11, 6, 7),
      endedAt: DateTime.utc(2026, 11, 6, 8),
      verdict: RideVerdict.unknown,
      distanceM: 9000,
      path: _road,
      route: tag,
    );
    expect(RideRecord.fromJson(ride.toJson()), ride);
    expect(ride.withVerdict(RideVerdict.bus).route, tag);
    expect(ride.withVerdict(RideVerdict.notBus).route, isNull);
    expect(ride.withRoute(null).route, isNull);
    final guide = GuideRide(
      to: _road.last,
      title: 'North',
      stages: const [GuideStage(400, AlertPattern.waves)],
      route: tag,
    );
    expect(GuideRide.fromJson(guide.toJson()), guide);
  });

  test("a ridden road is the route's direction along where the bus went", () {
    const ridden = [GeoPoint(6.92, 79.86), GeoPoint(6.98, 79.86)];
    final copy = north.alongRide(ridden);
    expect(
      (copy.routeId, copy.noteKey, copy.number),
      ('osm:9', north.noteKey, '9'),
    );
    expect(copy.board, north.board);
    expect(copy.path, ridden);
    expect(copy.ridden, isTrue);
    expect(copy.times, isEmpty);
    expect(copy.before, isEmpty);
    // A board line of the riders' own stays on it.
    expect(copy.withBoard(const PlaceNames(en: 'Up')).ridden, isTrue);
  });

  test('the buses a ride could have been: along it, the right way', () {
    final south = north.alongRide(_road.reversed.toList());
    const elsewhere = RouteDirection(
      routeId: 'osm:10',
      source: RouteSource.osm,
      number: '10',
      board: PlaceNames(en: 'East'),
      path: [GeoPoint(6.90, 79.95), GeoPoint(7.00, 79.95)],
    );
    // Along the ride, its bus part from start to end.
    expect(
      likelyBuses([
        elsewhere,
        south,
        north,
      ], path: _road.sublist(0, 2)).map((d) => d.number),
      ['9'],
    );
    // During a ride, near where you are.
    expect(
      likelyBuses([
        elsewhere,
        north,
      ], here: const GeoPoint(6.93, 79.851)).map((d) => d.number),
      ['9'],
    );
    expect(likelyBuses([north]), isEmpty);
  });

  test('the same bus twice keeps the one with times', () {
    const timed = RouteDirection(
      routeId: 'lmt:9',
      source: RouteSource.lmt,
      number: '9',
      board: PlaceNames(en: 'North'),
      path: [GeoPoint(6.899, 79.85), GeoPoint(7.00, 79.85)],
      times: [
        Departures(0x7f, [480, 600]),
      ],
    );
    final found = const WhichBus().find(
      [
        north.alongRide(const [
          GeoPoint(6.9005, 79.8501),
          GeoPoint(6.99, 79.85),
        ]),
        timed,
      ],
      from: const GeoPoint(6.9005, 79.8502),
      to: const GeoPoint(6.98, 79.8502),
      now: DateTime(2026, 11, 4, 7, 5),
    );
    expect(found.single.direction.routeId, 'lmt:9');
  });
}
