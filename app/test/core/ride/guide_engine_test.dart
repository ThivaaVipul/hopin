import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/guide_engine.dart';
import 'package:hopin/core/ride/patterns.dart';

import '../../fixtures/traces/traces.dart';

const ride = GuideRide(to: stop, title: 'Colombo Fort');

/// Every step the engine takes over [trace].
List<GuideStep> run(Trace trace, {GuideRide guide = ride}) {
  final engine = GuideEngine(guide);
  return [for (final fix in trace.fixes) ?engine.update(fix)];
}

/// The alerts, each with the distance it fired at.
List<(GuideAlert, double)> alerts(List<GuideStep> steps) => [
  for (final step in steps)
    if (step.alert case final alert?) (alert, step.status.metres),
];

void main() {
  const minute = Duration(minutes: 1);

  test('a ride: get ready, get off next, then ends still at the stop', () {
    final steps = run(
      Trace.from(5000).rideTo(40).wait(const Duration(seconds: 70)),
    );
    final fired = alerts(steps);
    expect(fired.map((a) => a.$1), const [StageDue(0), StageDue(1), Arrived()]);
    expect(fired[0].$2, inInclusiveRange(1460, 1500));
    expect(fired[1].$2, inInclusiveRange(360, 400));
    expect(steps.last.status.phase, GuidePhase.getOff);
    expect(steps.last.status.progress, closeTo(1, 0.01));
  });

  test('a fast bus gets "Get off next" about 45 seconds early', () {
    final fired = alerts(run(Trace.from(4000).rideTo(0, speed: 16)));
    final getOff = fired.firstWhere((a) => a.$1 == const StageDue(1));
    expect(getOff.$2, inInclusiveRange(16 * 45 - 80, 16 * 45));
  });

  test('stages already due at the start fire once, innermost only', () {
    final steps = run(Trace.from(300).rideTo(150));
    expect(alerts(steps).map((a) => a.$1), const [StageDue(1)]);
    expect(steps.first.status.phase, GuidePhase.getOff);
  });

  test('going past the stop warns once, and the guide goes on', () {
    final steps = run(
      Trace.from(3000).rideTo(-800).ride(-8, minute).rideTo(-100, speed: 1.4),
    );
    final fired = alerts(steps);
    expect(fired.map((a) => a.$1), const [
      StageDue(0),
      StageDue(1),
      StopPassed(),
    ]);
    expect(fired.last.$2, inInclusiveRange(300, 340));
    expect(
      steps.map((s) => s.status.phase),
      containsAllInOrder([
        GuidePhase.riding,
        GuidePhase.getOff,
        GuidePhase.passed,
        GuidePhase.getOff,
      ]),
    );
  });

  test('walking back to the stop after missing it ends the guide', () {
    final fired = alerts(
      run(
        Trace.from(2000)
            .rideTo(-500)
            .rideTo(20, speed: 1.4)
            .wait(const Duration(seconds: 65), jitter: 6),
      ),
    );
    expect(fired.map((a) => a.$1).last, const Arrived());
  });

  test('starting at the stop and riding away is not a missed stop', () {
    final fired = alerts(run(Trace.from(60).rideTo(-1500)));
    expect(fired.map((a) => a.$1), isNot(contains(const StopPassed())));
  });

  test('passing the stop at speed does not end the guide', () {
    final fired = alerts(run(Trace.from(1000).rideTo(-150, speed: 10)));
    expect(fired.map((a) => a.$1), isNot(contains(const Arrived())));
  });

  test('a GPS jump is not a fast bus', () {
    final fired = alerts(
      run(
        Trace.from(2500)
            .ride(8, minute)
            .jump(300000)
            .wait(const Duration(seconds: 20))
            .jump(2000)
            .ride(8, const Duration(seconds: 15))
            .rideTo(1300),
      ),
    );
    expect(fired.map((a) => a.$1), const [StageDue(0)]);
    expect(fired.single.$2, inInclusiveRange(1460, 1500));
  });

  test('time left comes from your recent speed and hides while still', () {
    final moving = run(Trace.from(8000).ride(10, const Duration(minutes: 3)));
    final last = moving.last.status;
    expect(last.left, isNotNull);
    expect(
      last.left!.inSeconds,
      closeTo(last.metres / 10, last.metres / 10 * 0.05),
    );

    final waiting = run(
      Trace.from(
        8000,
      ).ride(10, const Duration(minutes: 3)).wait(minute * 3, jitter: 10),
    );
    expect(waiting.last.status.left, isNull);
  });

  test('time left waits for enough fixes', () {
    final steps = run(Trace.from(3000).ride(10, const Duration(seconds: 20)));
    expect(steps.every((s) => s.status.left == null), isTrue);
  });

  test('vague fixes are ignored; only sure ones end the guide', () {
    final engine = GuideEngine(ride);
    expect(
      engine.update(RideFix(stop, DateTime.utc(2026), accuracy: 150)),
      isNull,
    );

    final roughAtStop = Trace.from(30, accuracy: 80).wait(minute * 3);
    expect(alerts(run(roughAtStop)).map((a) => a.$1), const [StageDue(1)]);
  });

  test('fixes out of order are ignored, and nothing follows arriving', () {
    final engine = GuideEngine(ride);
    final at = DateTime.utc(2026, 1, 1, 8);
    expect(engine.update(RideFix(stop, at)), isNotNull);
    expect(engine.update(RideFix(stop, at)), isNull);
    for (var s = 5; s <= 60; s += 5) {
      engine.update(RideFix(stop, at.add(Duration(seconds: s))));
    }
    expect(engine.update(RideFix(stop, at.add(minute * 2))), isNull);
  });

  test('progress runs from nothing to the stop', () {
    final steps = run(Trace.from(2000).rideTo(0));
    expect(steps.first.status.progress, 0);
    expect(steps[steps.length ~/ 2].status.progress, closeTo(0.5, 0.05));
    expect(steps.last.status.progress, closeTo(1, 0.01));
  });

  test('three stages fire in order', () {
    const three = GuideRide(
      to: stop,
      title: 'Colombo Fort',
      stages: [
        GuideStage(3000, AlertPattern.waves),
        GuideStage(1000, AlertPattern.heartbeat),
        GuideStage(300, AlertPattern.tripleKnock),
      ],
    );
    final fired = alerts(run(Trace.from(6000).rideTo(100), guide: three));
    expect(fired.map((a) => a.$1), const [
      StageDue(0),
      StageDue(1),
      StageDue(2),
    ]);
  });

  test('rides and statuses survive the trip to the ride service', () {
    const full = GuideRide(
      to: GeoPoint(6.9344, 79.8501),
      title: 'Colombo Fort',
      names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
      area: 'Fort, Colombo',
      language: 'ta',
    );
    expect(GuideRide.fromJson(full.toJson()), full);
    expect(GuideRide.fromJson({'lat': 1}), isNull);

    const status = GuideStatus(
      metres: 412.5,
      progress: 0.8,
      left: Duration(seconds: 95),
      phase: GuidePhase.getOff,
      at: GeoPoint(6.93, 79.85),
    );
    expect(GuideStatus.fromJson(status.toJson()), status);
    expect(
      GuideStatus.fromJson(const {'metres': 10, 'progress': 1}),
      const GuideStatus(metres: 10, progress: 1),
    );
  });
}
