import 'dart:math' as math;

import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/guide_engine.dart';

/// A stop on the way: where, and for how long.
class Halt {
  const Halt(this.point, this.seconds);

  final GeoPoint point;
  final int seconds;
}

/// The bus logic (docs/ARCHITECTURE.md, Ride detection), fed one fix at a
/// time while Android says the phone is in a vehicle. It keeps the path and
/// the halts, and scores how much the ride is like a bus: buses halt every
/// few hundred metres for 10 to 60 seconds and rarely hold the top speeds a
/// car reaches on an open road. The score errs towards asking: the answer
/// ("On a bus?") is cheap and is kept with these numbers to tune it.
class BusLogic {
  /// Moving slower than this (m/s) between fixes is a halt.
  static const halting = 1.5;

  /// Steps shorter than this are GPS wobble, not movement.
  static const wobble = 15.0;

  /// Halts shorter than this are not counted (a slow corner).
  static const minHalt = 8;

  /// Halts longer than this are not a bus stop (a jam, a meal).
  static const maxBusHalt = 90;

  /// Asked once the ride is at least this long and far.
  static const askAfter = Duration(minutes: 3);
  static const askAfterMetres = 600.0;

  /// At or above this score, ask "On a bus?".
  static const threshold = 0.6;

  /// Path points are kept at least this far apart.
  static const pathStep = 40.0;

  static const _sustained = Duration(seconds: 30);

  /// The fixes of the last [_sustained] or so, for the top speed.
  final _fixes = <RideFix>[];
  DateTime? _startedAt;
  final path = <GeoPoint>[];
  final halts = <Halt>[];
  var distance = 0.0;
  var topSpeed = 0.0;

  /// When the ride last moved; null before it first does.
  DateTime? movedAt;
  DateTime? _haltFrom;
  GeoPoint? _haltAt;
  var _moved = false;

  DateTime? get startedAt => _startedAt;
  DateTime? get lastAt => _fixes.isEmpty ? null : _fixes.last.at;

  /// Takes a fix; vague ones (over [GuideEngine.roughFix]) are ignored.
  void add(RideFix fix) {
    final accuracy = fix.accuracy;
    if (accuracy != null && accuracy > GuideEngine.roughFix) return;
    final previous = _fixes.isEmpty ? null : _fixes.last;
    if (previous != null && !fix.at.isAfter(previous.at)) return;
    _startedAt ??= fix.at;
    if (previous == null) {
      _fixes.add(fix);
      path.add(fix.point);
      return;
    }
    final seconds = fix.at.difference(previous.at).inMilliseconds / 1000;
    final step = previous.point.distanceTo(fix.point);
    // A jump faster than any bus is the GPS, not the ride: start over there.
    if (step > GuideEngine.fastest * seconds + GuideEngine.roughFix) {
      _fixes
        ..clear()
        ..add(fix);
      return;
    }
    _fixes
      ..add(fix)
      ..removeWhere((f) => fix.at.difference(f.at) > _sustained * 2);
    if (path.last.distanceTo(fix.point) >= pathStep) path.add(fix.point);
    if (step < math.max(wobble, halting * seconds)) {
      _haltFrom ??= previous.at;
      _haltAt ??= previous.point;
    } else {
      // Standing before the ride first moves is not a stop.
      _endHalt(previous.at);
      _moved = true;
      movedAt = fix.at;
      distance += step;
    }
    topSpeed = math.max(topSpeed, _sustainedSpeed());
  }

  void _endHalt(DateTime at) {
    final from = _haltFrom;
    final where = _haltAt;
    _haltFrom = null;
    _haltAt = null;
    if (from == null || where == null || !_moved) return;
    final seconds = at.difference(from).inSeconds;
    if (seconds >= minHalt) halts.add(Halt(where, seconds));
  }

  /// The highest speed held over [_sustained], so one jumpy fix doesn't count.
  double _sustainedSpeed() {
    final last = _fixes.last;
    final first = _fixes.firstWhere(
      (f) => last.at.difference(f.at) <= _sustained,
    );
    final seconds = last.at.difference(first.at).inMilliseconds / 1000;
    if (seconds < _sustained.inSeconds * 2 / 3) return 0;
    return first.point.distanceTo(last.point) / seconds;
  }

  Duration get length =>
      _fixes.isEmpty ? Duration.zero : lastAt!.difference(startedAt!);

  /// Halts that look like bus stops, per kilometre moved.
  double get busHaltsPerKm {
    if (distance < 100) return 0;
    final bus = halts.where((h) => h.seconds <= maxBusHalt).length;
    return bus / (distance / 1000);
  }

  /// From 0 (not like a bus) to 1: mostly the halts, some the speed.
  double get score {
    final haltScore = math.min(1.0, busHaltsPerKm);
    final speedScore = (1 - (topSpeed - 17) / (28 - 17)).clamp(0.0, 1.0);
    return 0.65 * haltScore + 0.35 * speedScore;
  }

  /// Whether to ask "On a bus?" now.
  bool get ask =>
      length >= askAfter && distance >= askAfterMetres && score >= threshold;

  /// The numbers the logic used, kept with the answer to tune it.
  Map<String, num> get features => {
    'minutes': (length.inSeconds / 60 * 10).round() / 10,
    'distanceKm': (distance / 100).round() / 10,
    'topSpeed': (topSpeed * 10).round() / 10,
    'halts': halts.length,
    'busHaltsPerKm': (busHaltsPerKm * 100).round() / 100,
    'longHalts': halts.where((h) => h.seconds > maxBusHalt).length,
    'score': (score * 100).round() / 100,
    'hour': startedAt?.toLocal().hour ?? 0,
  };
}
