import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/polyline.dart';

/// Where a route's data comes from (docs/ARCHITECTURE.md, Route data): a
/// route file the weekly job builds, or the riders, by hand.
enum RouteSource {
  osm,
  ntc,
  lmt,
  hand;

  /// The route file sources, each a file on the `data` release.
  static const files = [osm, ntc, lmt];
}

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
    this.before = const [],
    this.after = const [],
    this.stops = const [],
    this.start,
    this.end,
    this.stand,
    this.times = const [],
    this._noteKey,
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

  /// Its road as mapped; empty for an NTC route, which has its towns instead.
  final List<GeoPoint> path;

  /// The rest of a partly mapped road, guessed along real roads: from its
  /// first town to where the mapped road starts, and on from where it stops
  /// to its end town.
  final List<GeoPoint> before;
  final List<GeoPoint> after;

  /// Its stops; an NTC route's are the towns between its ends, with the
  /// minutes after it leaves.
  final List<RouteStop> stops;

  /// An NTC route's two towns, and a bus stand at the start.
  final GeoPoint? start;
  final GeoPoint? end;
  final RouteStop? stand;

  /// Departures from the first stop (LMT) or the start town (NTC).
  final List<Departures> times;

  /// What the riders' notes know this direction by: its ends as the route
  /// file names them, so a note's own board lines don't change it.
  String get noteKey =>
      _noteKey ?? '${_firstName(origin)}>${_firstName(board)}';
  final String? _noteKey;

  static String _firstName(PlaceNames names) =>
      names.en ?? names.ta ?? names.si ?? '';

  /// The same direction under other board lines (a rider's).
  RouteDirection withBoard(PlaceNames board) => RouteDirection(
    routeId: routeId,
    source: source,
    number: number,
    board: board,
    also: also,
    classes: classes,
    origin: origin,
    path: path,
    before: before,
    after: after,
    stops: stops,
    start: start,
    end: end,
    stand: stand,
    times: times,
    noteKey: noteKey,
  );

  /// A long-distance route: matched by its towns, not its road.
  bool get long => path.isEmpty;

  /// The whole road, guessed parts and all.
  List<GeoPoint> get road => [
    ...before,
    // The joins are the same point.
    ...(before.isNotEmpty && path.isNotEmpty ? path.skip(1) : path),
    ...(after.isNotEmpty ? after.skip(1) : const <GeoPoint>[]),
  ];

  @override
  List<Object?> get props => [routeId, number, board, origin, path.length];
}

/// A town a route added by hand names: where it is, and its names.
class RouteTown extends Equatable {
  const RouteTown(this.point, [this.names = const PlaceNames()]);

  final GeoPoint point;
  final PlaceNames names;

  @override
  List<Object?> get props => [point, names];
}

/// A route the riders added by hand (docs/PLAN.md, Which bus), shared by
/// both: its number, its two end towns, the towns it passes on the way, and
/// the road OSRM drew through them. It runs both ways.
class HandRoute extends Equatable {
  const HandRoute({
    required this.id,
    required this.number,
    required this.from,
    required this.to,
    this.via = const [],
    this.road = const [],
  });

  /// The id of a hand route's directions, for one made by [id].
  static String routeIdOf(String id) => 'hand:$id';

  /// The hand route's own id in a direction's [routeId], or null for a
  /// route from the route files.
  static String? idIn(String routeId) =>
      routeId.startsWith('hand:') ? routeId.substring(5) : null;

  final String id;
  final String number;
  final RouteTown from;
  final RouteTown to;
  final List<RouteTown> via;

  /// From [from] to [to] through [via], along real roads.
  final List<GeoPoint> road;

  String get routeId => routeIdOf(id);

  /// There and back, each with its far end town on the board.
  List<RouteDirection> get directions => [
    RouteDirection(
      routeId: routeId,
      source: RouteSource.hand,
      number: number,
      board: to.names,
      origin: from.names,
      path: road,
      start: from.point,
      end: to.point,
    ),
    RouteDirection(
      routeId: routeId,
      source: RouteSource.hand,
      number: number,
      board: from.names,
      origin: to.names,
      path: road.reversed.toList(growable: false),
      start: to.point,
      end: from.point,
    ),
  ];

  @override
  List<Object?> get props => [id, number, from, to, via, road];
}

/// A rider's change to one direction of a route from the route files
/// (docs/PLAN.md, Which bus), shared by both riders: board lines that stand
/// in for the file's (a line left out keeps the file's), and whether the
/// direction is removed. The newest note on a direction wins.
class RouteNote extends Equatable {
  const RouteNote({
    required this.route,
    required this.direction,
    required this.at,
    this.board = const PlaceNames(),
    this.removed = false,
  });

  /// The route's id and the direction's [RouteDirection.noteKey].
  final String route;
  final String direction;
  final DateTime at;
  final PlaceNames board;
  final bool removed;

  @override
  List<Object?> get props => [route, direction, at, board, removed];
}

/// A direction from the route files with the newest note on it, if any.
class NotedDirection extends Equatable {
  const NotedDirection(this.file, [this.note]);

  /// As the route file has it.
  final RouteDirection file;
  final RouteNote? note;

  /// With the note's board lines in place of the file's.
  RouteDirection get direction {
    final lines = note?.board;
    if (lines == null || lines.isEmpty) return file;
    final board = file.board;
    return file.withBoard(
      PlaceNames(
        en: lines.en ?? board.en,
        ta: lines.ta ?? board.ta,
        si: lines.si ?? board.si,
      ),
    );
  }

  /// Whether a rider gave it board lines of their own.
  bool get edited => !(note?.board.isEmpty ?? true);

  bool get removed => note?.removed ?? false;

  @override
  List<Object?> get props => [file, note];
}

/// Each direction with the newest of [notes] on it.
List<NotedDirection> withNotes(
  List<RouteDirection> directions,
  Iterable<RouteNote> notes,
) {
  final newest = <(String, String), RouteNote>{};
  for (final note in notes) {
    final key = (note.route, note.direction);
    final known = newest[key];
    if (known == null || note.at.isAfter(known.at)) newest[key] = note;
  }
  return [
    for (final direction in directions)
      NotedDirection(direction, newest[(direction.routeId, direction.noteKey)]),
  ];
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
  final source = RouteSource.files
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
  List<GeoPoint> line(String key) => switch (direction[key]) {
    final String encoded when encoded.isNotEmpty => _decode(encoded),
    _ => const <GeoPoint>[],
  };
  final path = line('path');
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
    before: path.isEmpty ? const [] : line('before'),
    after: path.isEmpty ? const [] : line('after'),
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
