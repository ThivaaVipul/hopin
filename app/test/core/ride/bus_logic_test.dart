import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/ride_record.dart';

import '../../fixtures/traces/traces.dart';

/// The logic after every fix of [trace].
BusLogic score(Trace trace) {
  final logic = BusLogic();
  trace.fixes.forEach(logic.add);
  return logic;
}

/// A town bus: [stops] times, 400 m at 9 m/s, then a 30-second halt.
Trace townBus({int stops = 6, double from = 6000}) {
  final trace = Trace.from(from);
  for (var i = 0; i < stops; i++) {
    trace
      ..ride(9, const Duration(seconds: 45))
      ..wait(const Duration(seconds: 30));
  }
  // A halt at the very end is the arrival, not a stop.
  return trace..ride(9, const Duration(seconds: 20));
}

void main() {
  test('a town bus that halts every 400 m is asked about', () {
    final logic = score(townBus());
    expect(logic.halts, hasLength(6));
    expect(
      logic.halts.every((h) => h.seconds >= 25 && h.seconds <= 35),
      isTrue,
    );
    expect(logic.busHaltsPerKm, closeTo(2.5, 0.5));
    expect(logic.score, greaterThanOrEqualTo(BusLogic.threshold));
    expect(logic.ask, isTrue);
  });

  test('not before three minutes', () {
    final logic = score(townBus(stops: 2));
    expect(logic.score, greaterThanOrEqualTo(BusLogic.threshold));
    expect(logic.ask, isFalse);
  });

  test('a car that never halts is not', () {
    final logic = score(Trace.from(9000).ride(15, const Duration(minutes: 6)));
    expect(logic.halts, isEmpty);
    expect(logic.ask, isFalse);
  });

  test('a car on an open road is not', () {
    final logic = score(
      Trace.from(20000)
          .ride(26, const Duration(minutes: 4))
          .wait(const Duration(seconds: 30))
          .ride(26, const Duration(minutes: 4)),
    );
    expect(logic.topSpeed, greaterThan(24));
    expect(logic.ask, isFalse);
  });

  test('a tuk-tuk with one junction stop is not', () {
    final logic = score(
      Trace.from(8000)
          .ride(10, const Duration(minutes: 2))
          .wait(const Duration(seconds: 20))
          .ride(10, const Duration(minutes: 3)),
    );
    expect(logic.halts, hasLength(1));
    expect(logic.ask, isFalse);
  });

  test('standing before the ride starts is not a halt', () {
    final logic = score(
      Trace.from(6000).wait(const Duration(minutes: 2), jitter: 5)
        ..ride(9, const Duration(seconds: 45)),
    );
    expect(logic.halts, isEmpty);
  });

  test('a long halt is kept but is not a bus stop', () {
    final logic = score(
      townBus(stops: 3)
        ..wait(const Duration(minutes: 3))
        ..ride(9, const Duration(seconds: 45)),
    );
    expect(logic.halts.last.seconds, greaterThan(BusLogic.maxBusHalt));
    expect(logic.features['longHalts'], 1);
  });

  test('a GPS jump does not count as distance or speed', () {
    final logic = score(
      Trace.from(6000).ride(9, const Duration(minutes: 1)).jump(300000)
        ..jump(5460)
        ..ride(9, const Duration(minutes: 1)),
    );
    expect(logic.distance, lessThan(1200));
    expect(logic.topSpeed, lessThan(12));
  });

  test('keeps the path sparse and the numbers for tuning', () {
    final logic = score(townBus());
    expect(logic.path.length, lessThan(townBus().fixes.length));
    for (var i = 1; i < logic.path.length; i++) {
      expect(
        logic.path[i - 1].distanceTo(logic.path[i]),
        greaterThanOrEqualTo(BusLogic.pathStep),
      );
    }
    expect(logic.features.keys, containsAll(['minutes', 'busHaltsPerKm']));
  });

  test('polylines and halts survive the round trip', () {
    const points = [
      GeoPoint(6.9344, 79.8501),
      GeoPoint(6.9301, 79.8522),
      GeoPoint(-1.5, -79.1234),
    ];
    expect(decodePolyline(encodePolyline(points)), points);
    expect(() => decodePolyline('_p~iF~ps|U_'), throwsFormatException);
  });

  test('a ride record keeps its path unless it was not a bus', () {
    final logic = score(townBus());
    final ended = DateTime.utc(2026, 1, 1, 9);
    final bus = RideRecord.fromLogic(
      logic,
      id: 'r1',
      verdict: RideVerdict.bus,
      endedAt: ended,
      guideTo: 'Colombo Fort',
    );
    expect(RideRecord.fromJson(bus.toJson()), bus);
    expect(bus.path, isNotEmpty);
    expect(bus.halts, hasLength(6));

    final car = RideRecord.fromLogic(
      logic,
      id: 'r2',
      verdict: RideVerdict.notBus,
      endedAt: ended,
    );
    expect(car.path, isEmpty);
    expect(car.halts, isEmpty);
    expect(car.features, isNotEmpty);
    expect(RideRecord.fromJson(car.toJson()), car);
    expect(bus.withVerdict(RideVerdict.notBus).path, isEmpty);
  });
}
