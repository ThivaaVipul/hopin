import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/guide.dart';

/// One GPS fix during a guide.
class RideFix {
  const RideFix(this.point, this.at, {this.accuracy});

  final GeoPoint point;
  final DateTime at;

  /// The fix's accuracy in metres, when the phone gives one.
  final double? accuracy;
}

/// Something the rider should feel.
sealed class GuideAlert extends Equatable {
  const GuideAlert();

  @override
  List<Object?> get props => [];
}

/// The ride's stage [index] is due.
class StageDue extends GuideAlert {
  const StageDue(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class StopPassed extends GuideAlert {
  const StopPassed();
}

/// The guide is over.
class Arrived extends GuideAlert {
  const Arrived();
}

class GuideStep {
  const GuideStep(this.status, [this.alert]);

  final GuideStatus status;
  final GuideAlert? alert;
}

/// The get-off guide's maths (docs/PLAN.md, The guide), fed one fix at a time.
///
/// Each stage fires once, when you are within its distance or, on a fast bus,
/// about [leadTime] away; when several come due at once only the innermost
/// fires. Being within [arriveWithin] and walking or still for [arriveAfter]
/// ends the guide. Having been within [closeBy], [passedBy] further on is a
/// missed stop: it fires once, and the guide goes on. Speeds come from how
/// far you moved, not the path, so GPS jitter while still reads as still.
class GuideEngine {
  GuideEngine(this.ride);

  final GuideRide ride;

  static const leadTime = Duration(seconds: 45);
  static const arriveWithin = 100.0;
  static const arriveAfter = Duration(minutes: 1);

  /// Below this (m/s) you are walking or still.
  static const walking = 2.5;

  /// Below this (m/s) there is no time left to show.
  static const still = 1.0;
  static const closeBy = 400.0;
  static const passedBy = 300.0;

  /// Faster than this between two fixes (m/s, about 145 km/h) is the GPS
  /// jumping, not a bus: speeds start again from the new fix.
  static const fastest = 40.0;

  /// Fixes vaguer than this are ignored.
  static const roughFix = 100.0;

  /// The guide ends or warns only on fixes at least this good.
  static const sureFix = 50.0;

  static const _average = Duration(minutes: 2);
  static const _now = Duration(seconds: 30);

  final _recent = <RideFix>[];
  double? _start;
  var _closest = double.infinity;
  var _due = -1;
  var _passed = false;
  DateTime? _hereSince;
  DateTime? _slowSince;
  var _over = false;

  /// Takes a fix; null when it is ignored or the guide is over.
  GuideStep? update(RideFix fix) {
    final accuracy = fix.accuracy;
    if (_over || (accuracy != null && accuracy > roughFix)) return null;
    if (_recent.isNotEmpty) {
      final last = _recent.last;
      if (!fix.at.isAfter(last.at)) return null;
      final seconds = fix.at.difference(last.at).inMilliseconds / 1000;
      if (last.point.distanceTo(fix.point) > fastest * seconds + roughFix) {
        _recent.clear();
      }
    }
    _recent
      ..add(fix)
      ..removeWhere((f) => fix.at.difference(f.at) > _average);

    final metres = fix.point.distanceTo(ride.to);
    final start = _start ??= metres;
    final sure = accuracy == null || accuracy <= sureFix;
    if (sure) _closest = math.min(_closest, metres);
    final now = _move(_now);
    final average = _move(_average)?.speed;

    GuideAlert? alert;
    if (sure) {
      if (metres > arriveWithin) {
        _hereSince = _slowSince = null;
      } else if (now != null && now.speed >= walking) {
        _hereSince ??= fix.at;
        _slowSince = null;
      } else {
        final here = _hereSince ??= fix.at;
        // Slow over the whole window, so slow since it began, though only
        // since you got here.
        final from = now?.from ?? fix.at;
        final since = _slowSince ??= from.isAfter(here) ? from : here;
        if (fix.at.difference(since) >= arriveAfter) {
          _over = true;
          alert = const Arrived();
        }
      }
      // Starting near the stop and riding away is not a missed stop.
      if (alert == null &&
          !_passed &&
          start > closeBy &&
          _closest <= closeBy &&
          metres >= _closest + passedBy) {
        _passed = true;
        alert = const StopPassed();
      }
    }
    if (alert == null) {
      final lead = math.min(now?.speed ?? 0, fastest) * leadTime.inSeconds;
      var due = _due;
      for (var i = _due + 1; i < ride.stages.length; i++) {
        if (metres <= math.max(ride.stages[i].metres.toDouble(), lead)) due = i;
      }
      if (due > _due) {
        _due = due;
        alert = StageDue(due);
      }
    }

    final GuidePhase phase;
    if (_passed && metres > _closest + passedBy / 2) {
      phase = GuidePhase.passed;
    } else if (_due == ride.stages.length - 1) {
      phase = GuidePhase.getOff;
    } else {
      phase = GuidePhase.riding;
    }
    return GuideStep(
      GuideStatus(
        metres: metres,
        progress: start <= 0 ? 1 : ((start - metres) / start).clamp(0, 1),
        left: average != null && average >= still
            ? Duration(seconds: (metres / average).round())
            : null,
        phase: phase,
        at: fix.point,
      ),
      alert,
    );
  }

  /// How far you moved over the last [window], per second, and when that
  /// stretch began; null until the fixes span a third of it.
  ({double speed, DateTime from})? _move(Duration window) {
    final last = _recent.last;
    final first = _recent.firstWhere((f) => last.at.difference(f.at) <= window);
    final seconds = last.at.difference(first.at).inMilliseconds / 1000;
    if (seconds < window.inSeconds / 3) return null;
    return (
      speed: first.point.distanceTo(last.point) / seconds,
      from: first.at,
    );
  }
}
