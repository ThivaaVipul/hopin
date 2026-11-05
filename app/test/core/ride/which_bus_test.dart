import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/ride/which_bus.dart';

/// A straight road north from just south of Colombo Fort, 0.01 degrees
/// (about 1.1 km) a step.
List<GeoPoint> road(int steps, {double from = 6.90}) => [
  for (var i = 0; i <= steps; i++) GeoPoint(from + i * 0.01, 79.85),
];

RouteDirection local(
  String number, {
  String board = 'North',
  List<GeoPoint>? path,
  List<RouteStop> stops = const [],
  List<Departures> times = const [],
}) => RouteDirection(
  routeId: 'osm:$number',
  source: RouteSource.osm,
  number: number,
  board: PlaceNames(en: board),
  path: path ?? road(5),
  stops: stops,
  times: times,
);

void main() {
  const bus = WhichBus();
  // A Wednesday, 07:05.
  final now = DateTime(2026, 11, 4, 7, 5);
  const home = GeoPoint(6.9005, 79.8512); // about 130 m off the road
  const work = GeoPoint(6.9400, 79.8505);

  test('a bus whose road passes near both ends, the right way', () {
    final found = bus.find([local('101')], from: home, to: work, now: now);
    expect(found.map((o) => o.direction.number), ['101']);
    final option = found.single;
    expect(option.walkTo, closeTo(130, 15));
    expect(option.walkFrom, closeTo(55, 15));
    expect(option.next, isEmpty);
  });

  test('not the other way, too far off the road, or too near to ride', () {
    final south = local('101', path: road(5).reversed.toList());
    expect(bus.find([south], from: home, to: work, now: now), isEmpty);
    const far = GeoPoint(6.94, 79.87); // about 2 km east
    expect(bus.find([local('101')], from: home, to: far, now: now), isEmpty);
    const near = GeoPoint(6.906, 79.85); // 600 m on
    expect(bus.find([local('101')], from: home, to: near, now: now), isEmpty);
  });

  test('boards at the nearest stop before where you get off', () {
    final found = bus.find(
      [
        local(
          'CM9',
          stops: const [
            RouteStop(GeoPoint(6.9, 79.85), name: 'First', minutes: 0),
            RouteStop(GeoPoint(6.902, 79.85), name: 'Second', minutes: 2),
            // Past where you'd get off: no use for boarding.
            RouteStop(GeoPoint(6.95, 79.85), name: 'Last', minutes: 20),
          ],
          times: const [
            Departures(0x1f, [420, 440, 500]),
            Departures(0x60, [600]),
          ],
        ),
      ],
      from: const GeoPoint(6.9025, 79.8505),
      to: work,
      now: now,
    );
    final option = found.single;
    expect(option.boardName, 'Second');
    // The departures from the first stop, two minutes on.
    expect(option.next, [
      DateTime(2026, 11, 4, 7, 22),
      DateTime(2026, 11, 4, 8, 22),
      // None left today after these: tomorrow's first.
      DateTime(2026, 11, 5, 7, 2),
    ]);
    expect(option.today, [422, 442, 502]);
  });

  test('the same bus twice shows once, the shorter walk', () {
    final found = bus.find(
      [local('06'), local('6', path: road(5, from: 6.8995))],
      from: home,
      to: work,
      now: now,
    );
    expect(found, hasLength(1));
  });

  test('buses with times come first, the soonest first', () {
    final found = bus.find(
      [
        local('1'),
        local(
          '2',
          board: 'Other',
          times: const [
            Departures(0x7f, [480]),
          ],
        ),
        local(
          '3',
          board: 'Third',
          times: const [
            Departures(0x7f, [430]),
          ],
        ),
      ],
      from: home,
      to: work,
      now: now,
    );
    expect(found.map((o) => o.direction.number), ['3', '2', '1']);
  });

  test('a long-distance route by its towns, from its bus stand', () {
    const start = GeoPoint(6.93, 79.85);
    const end = GeoPoint(7.29, 80.63); // about 95 km off
    const direction = RouteDirection(
      routeId: 'ntc:1:N',
      source: RouteSource.ntc,
      number: '1',
      board: PlaceNames(en: 'East'),
      start: start,
      end: end,
      stand: RouteStop(GeoPoint(6.935, 79.851), name: 'Central Bus Stand'),
      times: [
        Departures(0x7f, [400, 600]),
      ],
    );
    final found = bus.find(
      [direction],
      from: const GeoPoint(6.90, 79.86),
      to: const GeoPoint(7.30, 80.62),
      now: now,
    );
    final option = found.single;
    expect(option.boardName, 'Central Bus Stand');
    expect(option.next.first, DateTime(2026, 11, 4, 10));
    // Not for a trip inside one of its towns.
    expect(
      bus.find(
        [direction],
        from: const GeoPoint(6.90, 79.86),
        to: const GeoPoint(6.95, 79.87),
        now: now,
      ),
      isEmpty,
    );
  });

  test('nothing for a walk', () {
    expect(
      bus.find(
        [local('101')],
        from: home,
        to: const GeoPoint(6.903, 79.851),
        now: now,
      ),
      isEmpty,
    );
  });

  test('road spots', () {
    final spot = roadSpot(road(2), const GeoPoint(6.905, 79.851));
    expect(spot.along, closeTo(556, 5));
    expect(spot.away, closeTo(110, 5));
    expect(spot.point.lat, closeTo(6.905, 1e-6));
    expect(roadSpot(const [], home).away, double.infinity);
  });
}
