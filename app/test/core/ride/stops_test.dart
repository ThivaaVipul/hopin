import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/stops.dart';

/// Synthetic spots in Colombo, never real rides (CLAUDE.md).
const clockTower = GeoPoint(6.9344, 79.8430);
const lakeRoad = GeoPoint(6.9270, 79.8510);

GeoPoint east(GeoPoint from, double metres) =>
    GeoPoint(from.lat, from.lng + metres / (111195 * 0.9929));

RideHalts ride(String id, List<(GeoPoint, int)> halts) =>
    RideHalts(id, [for (final (point, seconds) in halts) Halt(point, seconds)]);

void main() {
  const finder = StopFinder();

  test('halts from two rides at one spot make a learned stop', () {
    final stops = finder.find(
      rides: [
        ride('a', [(lakeRoad, 30)]),
        ride('b', [(east(lakeRoad, 12), 45)]),
      ],
    );
    final stop = stops.single;
    expect(stop.learned, isTrue);
    expect(stop.rides, 2);
    expect(stop.point.distanceTo(lakeRoad), lessThan(10));
    expect(stop.id, startsWith('learned:6.9270,79.85'));
  });

  test('one ride, or one ride halting twice, is not enough', () {
    expect(
      finder.find(
        rides: [
          ride('a', [(lakeRoad, 30), (east(lakeRoad, 5), 20)]),
        ],
      ),
      isEmpty,
    );
  });

  test('only bus-like halts count: 10 to 90 seconds', () {
    expect(
      finder.find(
        rides: [
          ride('a', [(lakeRoad, 5)]),
          ride('b', [(lakeRoad, 200)]),
        ],
      ),
      isEmpty,
    );
  });

  test('spots apart are stops apart', () {
    final far = east(lakeRoad, 80);
    final stops = finder.find(
      rides: [
        ride('a', [(lakeRoad, 30), (far, 30)]),
        ride('b', [(lakeRoad, 40), (far, 40)]),
      ],
    );
    expect(stops, hasLength(2));
  });

  test('halts by an OSM stop count towards it, not a new one', () {
    const osm = OsmStop(
      id: 42,
      point: clockTower,
      names: PlaceNames(en: 'Clock Tower', si: 'ඔරලෝසු කණුව'),
    );
    final stops = finder.find(
      osm: [osm],
      rides: [
        ride('a', [(east(clockTower, 20), 30)]),
        ride('b', [(east(clockTower, -15), 30)]),
        ride('c', [(east(clockTower, 10), 30)]),
      ],
    );
    final stop = stops.single;
    expect(stop.id, 'osm:42');
    expect(stop.learned, isFalse);
    expect(stop.rides, 3);
    expect(stop.names, osm.names);
  });

  test('an OSM stop shows even before any ride halts there', () {
    const osm = OsmStop(id: 7, point: clockTower);
    expect(finder.find(osm: [osm], rides: const []).single.rides, 0);
  });

  test('the latest note renames a learned stop, or removes it', () {
    final rides = [
      ride('a', [(lakeRoad, 30)]),
      ride('b', [(lakeRoad, 30)]),
    ];
    final renamed = finder.find(
      rides: rides,
      notes: [
        StopNote(
          id: 'n1',
          point: east(lakeRoad, 8),
          at: DateTime.utc(2026, 1, 1),
          name: 'Lake gate',
        ),
      ],
    );
    expect(renamed.single.names.en, 'Lake gate');

    final removed = finder.find(
      rides: rides,
      notes: [
        StopNote(
          id: 'n1',
          point: lakeRoad,
          at: DateTime.utc(2026, 1, 1),
          name: 'Lake gate',
        ),
        StopNote(
          id: 'n2',
          point: east(lakeRoad, 5),
          at: DateTime.utc(2026, 1, 2),
          removed: true,
        ),
      ],
    );
    expect(removed, isEmpty);

    // A note elsewhere leaves it alone.
    final elsewhere = finder.find(
      rides: rides,
      notes: [
        StopNote(
          id: 'n3',
          point: east(lakeRoad, 200),
          at: DateTime.utc(2026, 1, 3),
          removed: true,
        ),
      ],
    );
    expect(elsewhere, hasLength(1));
  });

  test('the same halts make the same stops in any order', () {
    final rides = [
      ride('a', [(lakeRoad, 30), (east(lakeRoad, 25), 30)]),
      ride('b', [(east(lakeRoad, 10), 30), (east(lakeRoad, 35), 30)]),
    ];
    final once = finder.find(rides: rides);
    final again = finder.find(rides: rides.reversed.toList());
    expect(again, once);
  });

  group('a tap on the map', () {
    final near = Stop(id: 'osm:1', point: lakeRoad, source: StopSource.osm);
    final next = Stop(
      id: 'osm:2',
      point: east(lakeRoad, 60),
      source: StopSource.osm,
    );

    test('finds the nearest stop within a fingertip', () {
      // At zoom 16 a fingertip (24 pixels) is about 28 m here.
      expect(stopAt([near, next], east(lakeRoad, 15), 16)?.id, 'osm:1');
      expect(stopAt([near, next], east(lakeRoad, 45), 16)?.id, 'osm:2');
      expect(stopAt([near, next], east(lakeRoad, 25), 16)?.id, 'osm:1');
    });

    test('nothing when no stop is that close', () {
      expect(stopAt([near], east(lakeRoad, 40), 16), isNull);
      // Zoomed in further, the same finger covers fewer metres.
      expect(stopAt([near], east(lakeRoad, 20), 18), isNull);
      expect(stopAt(const [], lakeRoad, 16), isNull);
    });
  });
}
