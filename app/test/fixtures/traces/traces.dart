import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/guide_engine.dart';

/// Synthetic rides for the guide's tests, never real ones: a straight line
/// due north to [stop], one fix every 5 seconds, as the ride service gets them.
const stop = GeoPoint(6.9344, 79.8501);

/// Metres per degree of latitude.
const _metresPerDegree = 111320.0;

class Trace {
  /// Starts [metres] south of the stop (negative: already past it).
  Trace.from(double metres, {this.accuracy = 8}) : _south = metres {
    _fix();
  }

  /// The accuracy every fix reports.
  double? accuracy;
  final fixes = <RideFix>[];
  double _south;
  var _at = DateTime.utc(2026, 1, 1, 8);
  var _wobble = 0;

  static const step = Duration(seconds: 5);

  /// Heads north at [speed] m/s (negative: back south) for [time].
  Trace ride(double speed, Duration time) {
    for (var t = step; t <= time; t += step) {
      _south -= speed * step.inSeconds;
      _fix();
    }
    return this;
  }

  /// Rides at [speed] until [metres] south of the stop.
  Trace rideTo(double metres, {double speed = 8}) {
    final direction = metres < _south ? 1 : -1;
    while ((_south - metres) * direction > 0) {
      _south -= direction * speed * step.inSeconds;
      _fix();
    }
    return this;
  }

  /// The GPS jumps to [metres] south of the stop, as a stale or wrong fix
  /// does.
  Trace jump(double metres) {
    _south = metres;
    _fix();
    return this;
  }

  /// Stays put for [time], the fixes wobbling by up to [jitter] metres.
  Trace wait(Duration time, {double jitter = 0}) {
    for (var t = step; t <= time; t += step) {
      _fix(jitter: jitter);
    }
    return this;
  }

  void _fix({double jitter = 0}) {
    // A fixed wobble pattern, so every run is the same.
    const wobble = [0.0, 1.0, -0.6, 0.3, -1.0, 0.7];
    final offset = jitter * wobble[_wobble++ % wobble.length];
    fixes.add(
      RideFix(
        GeoPoint(
          stop.lat - (_south + offset) / _metresPerDegree,
          stop.lng + offset / _metresPerDegree,
        ),
        _at,
        accuracy: accuracy,
      ),
    );
    _at = _at.add(step);
  }
}
