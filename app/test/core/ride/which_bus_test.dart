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

  test('a route mapped only part of the way still goes to its end town', () {
    // Mapped for about 5.5 km; its end town 3.3 km past where that stops.
    const short = RouteDirection(
      routeId: 'osm:9',
      source: RouteSource.osm,
      number: '9',
      board: PlaceNames(en: 'North'),
      origin: PlaceNames(en: 'South'),
      path: [GeoPoint(6.90, 79.85), GeoPoint(6.95, 79.85)],
      start: GeoPoint(6.90, 79.85),
      end: GeoPoint(6.98, 79.85),
    );
    final found = bus.find(
      [short],
      from: home,
      to: const GeoPoint(6.985, 79.851),
      now: now,
    );
    expect(found.single.walkFrom, closeTo(567, 20));
    // Not a place off the road and well away from the town.
    expect(
      bus.find([short], from: home, to: const GeoPoint(6.97, 79.88), now: now),
      isEmpty,
    );
  });

  test('a route mapped from part way can be caught in its first town', () {
    const late = RouteDirection(
      routeId: 'osm:9',
      source: RouteSource.osm,
      number: '9',
      board: PlaceNames(en: 'North'),
      origin: PlaceNames(en: 'South'),
      path: [GeoPoint(6.92, 79.85), GeoPoint(6.97, 79.85)],
      start: GeoPoint(6.90, 79.85),
      end: GeoPoint(6.97, 79.85),
    );
    final option = bus
        .find(
          [late],
          from: const GeoPoint(6.901, 79.851),
          to: const GeoPoint(6.95, 79.8505),
          now: now,
        )
        .single;
    expect(option.boardAt, const GeoPoint(6.90, 79.85));
    expect(option.boardName, 'South');
  });

  test('a place along the guessed rest of a road finds the bus', () {
    // Mapped to 6.92, guessed on to its end town at 6.96.
    const guessed = RouteDirection(
      routeId: 'osm:9',
      source: RouteSource.osm,
      number: '9',
      board: PlaceNames(en: 'North'),
      path: [GeoPoint(6.90, 79.85), GeoPoint(6.92, 79.85)],
      after: [GeoPoint(6.92, 79.85), GeoPoint(6.96, 79.85)],
      start: GeoPoint(6.90, 79.85),
      end: GeoPoint(6.96, 79.85),
    );
    // On the guessed part, 2.2 km short of the end town.
    const along = GeoPoint(6.94, 79.8505);
    expect(guessed.road, const [
      GeoPoint(6.90, 79.85),
      GeoPoint(6.92, 79.85),
      GeoPoint(6.96, 79.85),
    ]);
    final found = bus.find([guessed], from: home, to: along, now: now);
    expect(found.single.walkFrom, closeTo(55, 15));
  });

  test('on a far trip the bus may be a longer way off', () {
    final long = local('15', path: road(20));
    // 1.5 km east of the road.
    const offRoad = GeoPoint(6.901, 79.8636);
    final far = bus.find(
      [long],
      from: offRoad,
      to: const GeoPoint(7.09, 79.85),
      now: now,
    );
    expect(far.single.walkTo, closeTo(1500, 50));
    // Not on a short one.
    expect(
      bus.find(
        [long],
        from: offRoad,
        to: const GeoPoint(6.93, 79.85),
        now: now,
      ),
      isEmpty,
    );
  });

  test('a long-distance bus from and to the towns on its way', () {
    const via = RouteDirection(
      routeId: 'ntc:9:N',
      source: RouteSource.ntc,
      number: '9',
      board: PlaceNames(en: 'Omega'),
      start: GeoPoint(6.90, 79.85),
      end: GeoPoint(8.00, 80.40),
      stand: RouteStop(GeoPoint(6.901, 79.851), name: 'Alpha Stand'),
      stops: [RouteStop(GeoPoint(7.40, 80.10), name: 'Middle', minutes: 90)],
      times: [
        Departures(0x7f, [480, 600]),
      ],
    );
    // On at the town on its way: its time there is the departure plus 90.
    final fromMiddle = bus
        .find(
          [via],
          from: const GeoPoint(7.41, 80.11),
          to: const GeoPoint(7.99, 80.39),
          now: now,
        )
        .single;
    expect(fromMiddle.boardName, 'Middle');
    expect(fromMiddle.next.first, DateTime(2026, 11, 4, 9, 30));
    // Off at it, from the start's stand.
    final toMiddle = bus
        .find(
          [via],
          from: const GeoPoint(6.90, 79.85),
          to: const GeoPoint(7.40, 80.10),
          now: now,
        )
        .single;
    expect(toMiddle.boardName, 'Alpha Stand');
    expect(toMiddle.walkFrom, lessThan(10));
    // Not backwards.
    expect(
      bus.find(
        [via],
        from: const GeoPoint(7.40, 80.10),
        to: const GeoPoint(6.90, 79.85),
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
