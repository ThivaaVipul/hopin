import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/stops.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:http/http.dart' as http;

class OverpassException implements Exception {
  const OverpassException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'Overpass answered $statusCode';
}

/// A square of the map, about 5.5 km a side, fetched as one (docs/PLAN.md,
/// Sharing and stops).
class StopTile extends Equatable {
  const StopTile(this.row, this.column);

  factory StopTile.at(GeoPoint point) => StopTile(
    (point.lat * perDegree).floor(),
    (point.lng * perDegree).floor(),
  );

  /// Squares per degree: 0.05 degrees a side. Edges are worked out by
  /// dividing, so they land exactly on the round numbers.
  static const perDegree = 20;

  final int row;
  final int column;

  String get key => '$row/$column';
  double get south => row / perDegree;
  double get west => column / perDegree;
  double get north => (row + 1) / perDegree;
  double get east => (column + 1) / perDegree;

  @override
  List<Object?> get props => [row, column];
}

/// OpenStreetMap's bus stops, from the Overpass API: one square at a time,
/// at most one request a second, with an identifying user agent.
class Overpass {
  Overpass({
    http.Client? client,
    DateTime Function()? clock,
    Future<void> Function(Duration)? wait,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  static const _url = 'https://overpass-api.de/api/interpreter';

  final http.Client _client;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _wait;
  DateTime? _last;

  Future<List<OsmStop>> stops(StopTile tile) async {
    final last = _last;
    if (last != null) {
      final gap = _clock().difference(last);
      if (gap < const Duration(seconds: 1)) {
        await _wait(const Duration(seconds: 1) - gap);
      }
    }
    _last = _clock();
    final box = [
      tile.south,
      tile.west,
      tile.north,
      tile.east,
    ].map((v) => v.toStringAsFixed(4)).join(',');
    final query =
        '[out:json][timeout:25];'
        '(node["highway"="bus_stop"]($box);'
        'node["public_transport"="platform"]["bus"="yes"]($box););'
        'out body;';
    final response = await _client.post(
      Uri.parse(_url),
      headers: {'User-Agent': Nominatim.userAgent},
      body: {'data': query},
    );
    if (response.statusCode != 200) {
      throw OverpassException(response.statusCode);
    }
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    final elements = body is Map ? body['elements'] : null;
    return [
      if (elements is List)
        for (final element in elements) ?osmStopFrom(element),
    ];
  }
}

/// One Overpass node as a stop; null when it isn't one.
OsmStop? osmStopFrom(Object? element) {
  if (element is! Map) return null;
  final id = element['id'];
  final lat = element['lat'];
  final lon = element['lon'];
  if (id is! int || lat is! num || lon is! num) return null;
  final tags = element['tags'] is Map
      ? element['tags'] as Map
      : const <String, Object?>{};
  String? tag(String key) {
    final value = tags[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  return OsmStop(
    id: id,
    point: GeoPoint(lat.toDouble(), lon.toDouble()),
    names: PlaceNames(
      en: tag('name:en') ?? tag('name'),
      ta: tag('name:ta'),
      si: tag('name:si'),
    ),
  );
}
