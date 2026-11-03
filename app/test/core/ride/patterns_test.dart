import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/ride/patterns.dart';

/// Android plays [buzz] as timings alone on phones without amplitude control,
/// so it must take strict off and on turns and end on a buzz.
void expectPlayable(Buzz buzz) {
  expect(buzz.timings.length, buzz.amplitudes.length);
  expect(buzz.timings.length.isEven, isTrue, reason: 'ends on a buzz');
  for (var i = 0; i < buzz.timings.length; i++) {
    expect(buzz.timings[i], greaterThanOrEqualTo(0));
    if (i.isEven) {
      expect(buzz.amplitudes[i], 0, reason: 'segment $i is a pause');
    } else {
      expect(buzz.amplitudes[i], inInclusiveRange(1, 255));
      expect(buzz.timings[i], greaterThan(0));
    }
  }
}

void main() {
  test('every pattern is playable and short', () {
    for (final pattern in AlertPattern.values) {
      expectPlayable(pattern.buzz);
      expect(
        pattern.buzz.length,
        lessThanOrEqualTo(const Duration(seconds: 3)),
        reason: pattern.name,
      );
    }
    expectPlayable(passedBuzz);
    expectPlayable(arrivedBuzz);
  });

  test('the six patterns feel different', () {
    expect(AlertPattern.values, hasLength(6));
    final shapes = {
      for (final pattern in AlertPattern.values) pattern.buzz.timings.join(','),
    };
    expect(shapes, hasLength(6));
  });

  test('a missed stop buzzes longer and harder than any choice', () {
    final longest = AlertPattern.values
        .map((p) => p.buzz.length)
        .reduce((a, b) => a > b ? a : b);
    expect(passedBuzz.length, greaterThan(longest));
    expect(passedBuzz.amplitudes.where((a) => a > 0), everyElement(255));
  });

  test('a repeated buzz plays it again after a pause', () {
    final twice = AlertPattern.tripleKnock.buzz.repeated(2);
    expectPlayable(twice);
    expect(
      twice.length,
      AlertPattern.tripleKnock.buzz.length * 2 +
          const Duration(milliseconds: 700),
    );
    expect(AlertPattern.tripleKnock.buzz.timings, hasLength(6));
  });
}
