import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/routes.dart';

/// A bus that takes you to a place (docs/PLAN.md, Which bus): where to board
/// it, how far to walk, and when it comes.
class BusOption extends Equatable {
  const BusOption({
    required this.direction,
    required this.boardAt,
    required this.walkTo,
    required this.walkFrom,
    this.boardName,
    this.next = const [],
    this.today = const [],
  });

  final RouteDirection direction;

  /// Where to get on: a stop of the route, its bus stand, a town on its way,
  /// or the road.
  final GeoPoint boardAt;
  final String? boardName;

  /// Metres to walk to the bus, and from where you get off.
  final double walkTo;
  final double walkFrom;

  /// The next three times it comes where you board, into tomorrow if need be.
  final List<DateTime> next;

  /// All of today's times where you board, in minutes after midnight (past
  /// 1440 for a bus that comes after midnight).
  final List<int> today;

  @override
  List<Object?> get props => [direction, boardAt, next];
}

/// The road position nearest a point: metres along the road and away from it.
typedef RoadSpot = ({double along, double away, GeoPoint point});

/// Finds the buses that go from one place to another: one bus, no changes.
class WhichBus {
  const WhichBus();

  /// How far you may walk to the route's road, at each end.
  static const walk = 500.0;

  /// On a trip this long, the bus may be this far from you (a walk or a tuk
  /// to the main road), and from where you are going.
  static const farTrip = 10000.0;
  static const farWalk = 2000.0;

  /// Closer than this, walking beats any bus.
  static const shortest = 800.0;

  /// The bus must take you at least this far along its road.
  static const ride = 300.0;

  /// A long-distance route counts from this far around its towns, or a third
  /// of the way to the next of its towns.
  static const town = 10000.0;

  /// A place this close to a route's end town is served by it even where its
  /// road stops short of the town (OpenStreetMap often maps only part of a
  /// route, and a guess may be missing); the same for getting on near its
  /// first town.
  static const endTown = 2000.0;

  List<BusOption> find(
    Iterable<RouteDirection> directions, {
    required GeoPoint from,
    required GeoPoint to,
    required DateTime now,
  }) {
    final trip = from.distanceTo(to);
    if (trip < shortest) return const [];
    final reach = trip >= farTrip ? farWalk : walk;
    final found = <String, BusOption>{};
    for (final direction in directions) {
      final option = direction.long
          ? _byTowns(direction, from, to, now)
          : _byRoad(direction, from, to, now, reach);
      if (option == null) continue;
      // The same bus from two sources (or two mappings) shows once.
      final board = direction.board;
      final key =
          '${plainNumber(direction.number)}|${board.en ?? board.ta ?? board.si}';
      final known = found[key];
      if (known == null || _walk(option) < _walk(known)) found[key] = option;
    }
    return found.values.toList()..sort(_soonest);
  }

  static double _walk(BusOption option) => option.walkTo + option.walkFrom;

  /// Buses with times first, the soonest first; then by the walk.
  static int _soonest(BusOption a, BusOption b) {
    if (a.next.isEmpty != b.next.isEmpty) return a.next.isEmpty ? 1 : -1;
    if (a.next.isNotEmpty) {
      final by = a.next.first.compareTo(b.next.first);
      if (by != 0) return by;
    }
    return _walk(a).compareTo(_walk(b));
  }

  BusOption? _byRoad(
    RouteDirection direction,
    GeoPoint from,
    GeoPoint to,
    DateTime now,
    double reach,
  ) {
    // The whole road, its guessed parts too.
    final road = _roads[direction] ??= direction.road;
    // Getting on in the first town or off in the end town, past where the
    // road stops short of it.
    final inStart = _pastRoad(direction.start, road.first, from);
    final inEnd = _pastRoad(direction.end, road.last, to);
    final box = _boxes[direction] ??= _Box.around(road);
    if ((!inStart && !box.near(from, reach)) ||
        (!inEnd && !box.near(to, reach))) {
      return null;
    }
    final on = roadSpot(road, from);
    final off = roadSpot(road, to);
    final boardsOnRoad = on.away <= reach;
    final leavesOnRoad = off.away <= reach;
    if (!boardsOnRoad && !inStart) return null;
    if (!leavesOnRoad && !inEnd) return null;
    final onAlong = boardsOnRoad ? on.along : 0.0;
    final offAlong = leavesOnRoad
        ? off.along
        : (_lengths[direction] ??= _length(road)) +
              direction.end!.distanceTo(road.last);
    if (offAlong - onAlong < ride) return null;
    // Board at the route's stop nearest you, before where you get off.
    final alongs = _stopAlongs[direction] ??= [
      for (final stop in direction.stops) roadSpot(road, stop.point).along,
    ];
    RouteStop? stop;
    if (boardsOnRoad) {
      var best = math.min(reach, on.away + walk);
      for (var i = 0; i < direction.stops.length; i++) {
        final candidate = direction.stops[i];
        final away = candidate.point.distanceTo(from);
        if (away <= best && alongs[i] < offAlong - ride / 2) {
          best = away;
          stop = candidate;
        }
      }
    }
    final boardAt = stop?.point ?? (boardsOnRoad ? on.point : direction.start!);
    final minutes = _minutesAt(direction, alongs, stop, on);
    final times = _timesAt(direction, minutes, now);
    final origin = direction.origin;
    return BusOption(
      direction: direction,
      boardAt: boardAt,
      // In its first town: board there, wherever in town it stops.
      boardName: stop?.name ?? (boardsOnRoad ? null : origin.en ?? origin.ta),
      walkTo: from.distanceTo(boardAt),
      walkFrom: leavesOnRoad ? off.away : to.distanceTo(direction.end!),
      next: times.next,
      today: times.today,
    );
  }

  /// Whether [point] is near a route's [town] while its road ends short of
  /// it, at [roadEnd].
  static bool _pastRoad(GeoPoint? town, GeoPoint roadEnd, GeoPoint point) =>
      town != null &&
      point.distanceTo(town) <= endTown &&
      roadEnd.distanceTo(town) > walk;

  static double _length(List<GeoPoint> path) {
    var total = 0.0;
    for (var i = 0; i + 1 < path.length; i++) {
      total += path[i].distanceTo(path[i + 1]);
    }
    return total;
  }

  /// Minutes from the first stop to where you board: that stop's, or the
  /// nearest timed stop's along the road.
  static int _minutesAt(
    RouteDirection direction,
    List<double> alongs,
    RouteStop? stop,
    RoadSpot on,
  ) {
    if (stop?.minutes case final minutes?) return minutes;
    int? nearest;
    var closest = double.infinity;
    for (var i = 0; i < direction.stops.length; i++) {
      final minutes = direction.stops[i].minutes;
      final gap = (alongs[i] - on.along).abs();
      if (minutes != null && gap < closest) {
        closest = gap;
        nearest = minutes;
      }
    }
    return nearest ?? 0;
  }

  /// A long-distance route by its towns: its start, the towns on its way
  /// (with their minutes) and its end. You get on at one of them and off at a
  /// later one, each within [town], or a third of the way to its nearest
  /// neighbour.
  BusOption? _byTowns(
    RouteDirection direction,
    GeoPoint from,
    GeoPoint to,
    DateTime now,
  ) {
    final start = direction.start;
    final end = direction.end;
    if (start == null || end == null) return null;
    final towns = [
      (point: start, minutes: 0, name: null as String?),
      for (final stop in direction.stops)
        if (stop.minutes != null)
          (point: stop.point, minutes: stop.minutes!, name: stop.name),
      (point: end, minutes: -1, name: null as String?),
    ];
    double around(int i) {
      var nearest = double.infinity;
      if (i > 0) nearest = towns[i].point.distanceTo(towns[i - 1].point);
      if (i + 1 < towns.length) {
        nearest = math.min(
          nearest,
          towns[i].point.distanceTo(towns[i + 1].point),
        );
      }
      return math.min(town, nearest / 3);
    }

    final on = [
      for (var i = 0; i + 1 < towns.length; i++)
        if (from.distanceTo(towns[i].point) <= around(i)) i,
    ].firstOrNull;
    if (on == null) return null;
    final off = [
      for (var i = towns.length - 1; i > on; i--)
        if (to.distanceTo(towns[i].point) <= around(i)) i,
    ].firstOrNull;
    if (off == null) return null;
    // At its start, the bus leaves from its stand; on its way, from the town.
    final stand = on == 0 ? direction.stand : null;
    final boardAt = stand?.point ?? towns[on].point;
    final times = _timesAt(direction, towns[on].minutes, now);
    return BusOption(
      direction: direction,
      boardAt: boardAt,
      boardName: stand?.name ?? towns[on].name,
      walkTo: from.distanceTo(boardAt),
      walkFrom: to.distanceTo(towns[off].point),
      next: times.next,
      today: times.today,
    );
  }

  static ({List<DateTime> next, List<int> today}) _timesAt(
    RouteDirection direction,
    int offset,
    DateTime now,
  ) {
    if (direction.times.isEmpty) return (next: const [], today: const []);
    List<int> on(DateTime day) => [
      for (final departures in direction.times)
        if (departures.runsOn(day))
          for (final minute in departures.minutes) minute + offset,
    ]..sort();
    final midnight = DateTime(now.year, now.month, now.day);
    final today = on(midnight);
    final past = now.difference(midnight).inMinutes;
    final next = [
      for (final minute in today)
        if (minute >= past) midnight.add(Duration(minutes: minute)),
    ];
    if (next.length < 3) {
      final tomorrow = DateTime(now.year, now.month, now.day + 1);
      next.addAll([
        for (final minute in on(tomorrow))
          tomorrow.add(Duration(minutes: minute)),
      ]);
    }
    return (next: next.take(3).toList(), today: today);
  }
}

/// Worked out once per direction: its whole road, its stops' metres along
/// it, the box around it, and its length.
final _roads = Expando<List<GeoPoint>>('roads');
final _stopAlongs = Expando<List<double>>('stop alongs');
final _boxes = Expando<_Box>('road boxes');
final _lengths = Expando<double>('road lengths');

/// A road's bounding box, for a quick no.
class _Box {
  _Box.around(List<GeoPoint> path)
    : south = path.map((p) => p.lat).reduce(math.min),
      north = path.map((p) => p.lat).reduce(math.max),
      west = path.map((p) => p.lng).reduce(math.min),
      east = path.map((p) => p.lng).reduce(math.max);

  final double south;
  final double north;
  final double west;
  final double east;

  /// Whether [point] is within [metres] of the box, a little over.
  bool near(GeoPoint point, double metres) {
    final margin = metres / 100000;
    return point.lat >= south - margin &&
        point.lat <= north + margin &&
        point.lng >= west - margin &&
        point.lng <= east + margin;
  }
}

/// Where [point] falls on [path]: metres along it to the nearest spot, how far
/// off the road it is, and the spot itself. Flat local maths, plenty for a
/// bus route.
RoadSpot roadSpot(List<GeoPoint> path, GeoPoint point) {
  if (path.isEmpty) {
    return (along: 0, away: double.infinity, point: point);
  }
  if (path.length == 1) {
    return (along: 0, away: path.first.distanceTo(point), point: path.first);
  }
  var best = (along: 0.0, away: double.infinity, point: path.first);
  var along = 0.0;
  for (var i = 0; i + 1 < path.length; i++) {
    final a = path[i];
    final b = path[i + 1];
    final step = a.distanceTo(b);
    // Metres east and north of a, for b and the point.
    final scale = math.cos(a.lat * math.pi / 180);
    const metresPerDegree = 111195.0;
    final bx = (b.lng - a.lng) * scale * metresPerDegree;
    final by = (b.lat - a.lat) * metresPerDegree;
    final px = (point.lng - a.lng) * scale * metresPerDegree;
    final py = (point.lat - a.lat) * metresPerDegree;
    final span = bx * bx + by * by;
    final t = span == 0
        ? 0.0
        : ((px * bx + py * by) / span).clamp(0.0, 1.0).toDouble();
    final away = math.sqrt(math.pow(px - t * bx, 2) + math.pow(py - t * by, 2));
    if (away < best.away) {
      best = (
        along: along + t * step,
        away: away,
        point: GeoPoint(
          a.lat + t * (b.lat - a.lat),
          a.lng + t * (b.lng - a.lng),
        ),
      );
    }
    along += step;
  }
  return best;
}
