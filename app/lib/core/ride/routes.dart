import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/polyline.dart';

/// Where a route's data comes from (docs/ARCHITECTURE.md, Route data).
enum RouteSource { osm, ntc, lmt }

/// A route's departures on some days of the week.
class Departures extends Equatable {
  const Departures(this.days, this.minutes);

  /// Seven bits, Monday first (bit 0).
  final int days;

  /// Minutes after midnight, in order.
  final List<int> minutes;

  /// Whether these run on [date]'s day of the week.
  bool runsOn(DateTime date) => days & (1 << (date.weekday - 1)) != 0;

  @override
  List<Object?> get props => [days, minutes];
}

/// A stop along a route: its own name and the minutes from the route's first
/// stop, where the source gives them (LMT's do; OpenStreetMap's are points).
class RouteStop extends Equatable {
  const RouteStop(this.point, {this.name, this.minutes});

  final GeoPoint point;
  final String? name;
  final int? minutes;

  @override
  List<Object?> get props => [point, name, minutes];
}

/// One way of a bus route: what its board says and the road it takes.
class RouteDirection extends Equatable {
  const RouteDirection({
    required this.routeId,
    required this.source,
    required this.number,
    required this.board,
    this.also = const [],
    this.classes = const [],
    this.origin = const PlaceNames(),
    this.path = const [],
    this.stops = const [],
    this.start,
    this.end,
    this.stand,
    this.times = const [],
  });

  final String routeId;
  final RouteSource source;

  /// As on the bus ("138", "15-87", "CM03").
  final String number;

  /// Other numbers its trips may carry (an NTC sheet of several routes).
  final List<String> also;

  /// NTC's classes: N, SL, L, AC, EX.
  final List<String> classes;

  /// The end town, as on the bus's board.
  final PlaceNames board;
  final PlaceNames origin;

  /// Its road; empty for an NTC route, which has only its two towns.
  final List<GeoPoint> path;
  final List<RouteStop> stops;

  /// An NTC route's two towns, and a bus stand at the start.
  final GeoPoint? start;
  final GeoPoint? end;
  final RouteStop? stand;

  /// Departures from the first stop (LMT) or the start town (NTC).
  final List<Departures> times;

  /// A long-distance route: matched by its towns, not its road.
  bool get long => path.isEmpty;

  @override
  List<Object?> get props => [routeId, number, board, origin, path.length];
}

/// The route data format the job writes (scripts/data/build_data.py).
const routeFileFormat = 1;

/// A route number for comparing: "06" and "6", "15/87" and "15-87" are one.
String plainNumber(String number) => number
    .trim()
    .replaceAll('/', '-')
    .replaceAllMapped(RegExp(r'(^|-)0+(?=\d)'), (m) => m[1]!)
    .toUpperCase();

/// The directions in one route file; throws a [FormatException] for a file
/// that isn't one (or is a newer format than this app reads).
List<RouteDirection> parseRouteFile(String body) {
  final decoded = jsonDecode(body);
  if (decoded is! Map<String, Object?> ||
      decoded['format'] != routeFileFormat) {
    throw const FormatException('not a route file');
  }
  final source = RouteSource.values
      .where((s) => s.name == decoded['source'])
      .firstOrNull;
  final routes = decoded['routes'];
  if (source == null || routes is! List) {
    throw const FormatException('not a route file');
  }
  return [
    for (final route in routes.whereType<Map<String, Object?>>())
      for (final direction
          in (route['directions'] as List? ?? const [])
              .whereType<Map<String, Object?>>())
        ?_direction(source, route, direction),
  ];
}

RouteDirection? _direction(
  RouteSource source,
  Map<String, Object?> route,
  Map<String, Object?> direction,
) {
  final id = route['id'];
  final number = route['number'];
  final board = _names(direction['board']);
  if (id is! String || number is! String || board.isEmpty) return null;
  final path = switch (direction['path']) {
    final String encoded when encoded.isNotEmpty => _decode(encoded),
    _ => const <GeoPoint>[],
  };
  final ends = direction['ends'];
  final long = path.isEmpty;
  // A route with no road needs its two towns to be matched at all.
  if (long && (ends is! List || ends.length != 2)) return null;
  return RouteDirection(
    routeId: id,
    source: source,
    number: number,
    also: _strings(route['also']),
    classes: _strings(route['classes']),
    board: board,
    origin: _names(direction['origin']),
    path: path,
    stops: [
      for (final stop in (direction['stops'] as List? ?? const []))
        ?_stop(stop),
    ],
    start: ends is List && ends.length == 2 ? _point(ends[0]) : null,
    end: ends is List && ends.length == 2 ? _point(ends[1]) : null,
    stand: _stop(direction['stand']),
    times: [
      for (final entry
          in (direction['times'] as List? ?? const [])
              .whereType<Map<String, Object?>>())
        if (entry case {
          'days': final int days,
          'departs': final List<Object?> departs,
        })
          Departures(days, [...departs.whereType<int>()]..sort()),
    ],
  );
}

List<GeoPoint> _decode(String encoded) {
  try {
    return decodePolyline(encoded);
  } on FormatException {
    return const [];
  }
}

PlaceNames _names(Object? value) {
  if (value is! Map) return const PlaceNames();
  String? text(String key) => switch (value[key]) {
    final String name when name.trim().isNotEmpty => name.trim(),
    _ => null,
  };
  return PlaceNames(en: text('en'), ta: text('ta'), si: text('si'));
}

List<String> _strings(Object? value) =>
    value is List ? [...value.whereType<String>()] : const [];

GeoPoint? _point(Object? value) {
  if (value is! List || value.length < 2) return null;
  final lat = value[0];
  final lng = value[1];
  if (lat is! num || lng is! num) return null;
  return GeoPoint(lat.toDouble(), lng.toDouble());
}

/// [lat, lng], [lat, lng, name] or [lat, lng, name, minutes].
RouteStop? _stop(Object? value) {
  final point = _point(value);
  if (point == null || value is! List) return null;
  final name = value.length > 2 && value[2] is String
      ? value[2] as String
      : null;
  final minutes = value.length > 3 && value[3] is int ? value[3] as int : null;
  return RouteStop(point, name: name, minutes: minutes);
}
