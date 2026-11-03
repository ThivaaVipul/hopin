/// A vibration as Android plays it: [timings] in milliseconds alternate off
/// and on, starting with a pause, and [amplitudes] give each segment's
/// strength from 1 to 255 (0 for the pauses).
///
/// Phones without amplitude control play the timings alone, so every pattern
/// keeps strict off and on turns and carries its shape in the timings too.
class Buzz {
  const Buzz(this.timings, this.amplitudes);

  final List<int> timings;
  final List<int> amplitudes;

  Duration get length =>
      Duration(milliseconds: timings.fold(0, (sum, ms) => sum + ms));

  /// This buzz [times] over with [gap] between, so an alert is still felt on
  /// a shaky bus.
  Buzz repeated(int times, {Duration gap = const Duration(milliseconds: 700)}) {
    final out = Buzz([...timings], [...amplitudes]);
    for (var i = 1; i < times; i++) {
      out.timings.addAll([
        gap.inMilliseconds + timings.first,
        ...timings.skip(1),
      ]);
      out.amplitudes.addAll(amplitudes);
    }
    return out;
  }
}

/// The patterns an alert stage can use (docs/PLAN.md, The guide).
enum AlertPattern {
  gentleDoubleTap(Buzz([0, 70, 140, 70], [0, 150, 0, 150])),
  strongLongBuzz(Buzz([0, 1000], [0, 255])),
  heartbeat(
    Buzz(
      [0, 90, 110, 170, 520, 90, 110, 170],
      [0, 170, 0, 255, 0, 170, 0, 255],
    ),
  ),
  tripleKnock(Buzz([0, 70, 120, 70, 120, 70], [0, 255, 0, 255, 0, 255])),
  rising(
    Buzz([0, 100, 90, 160, 90, 240, 90, 360], [0, 70, 0, 130, 0, 190, 0, 255]),
  ),
  waves(
    Buzz(
      [0, 90, 40, 140, 40, 220, 40, 140, 40, 90],
      [0, 60, 0, 130, 0, 230, 0, 130, 0, 60],
    ),
  );

  const AlertPattern(this.buzz);

  final Buzz buzz;
}

/// "You passed your stop": the strongest pattern, never one of the choices.
const passedBuzz = Buzz(
  [0, 700, 200, 700, 200, 700, 200, 1400],
  [0, 255, 0, 255, 0, 255, 0, 255],
);

/// The guide ends at your stop with one gentle tap.
const arrivedBuzz = Buzz([0, 90], [0, 150]);
