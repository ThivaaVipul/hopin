import 'dart:convert';

import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:http/http.dart' as http;

class NominatimException implements Exception {
  const NominatimException(this.statusCode);
  final int statusCode;

  @override
  String toString() => 'Nominatim answered $statusCode';
}

/// OpenStreetMap's place search (docs/ARCHITECTURE.md, Search), within its
/// usage policy: searched on request (never as you type), at most one request a
/// second, an identifying user agent, and answers cached.
class Nominatim {
  Nominatim({
    http.Client? client,
    DateTime Function()? clock,
    Future<void> Function(Duration)? wait,
  }) : _client = client ?? http.Client(),
       _clock = clock ?? DateTime.now,
       _wait = wait ?? Future<void>.delayed;

  static const userAgent = 'Hopin/0.2 (+https://github.com/ThivaaVipul/hopin)';
  static const _host = 'nominatim.openstreetmap.org';

  final http.Client _client;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _wait;
  final _cache = <String, Object>{};
  DateTime? _last;

  /// Places matching [query] in Sri Lanka, favouring those around [near].
  Future<List<Destination>> search(String query, {GeoPoint? near}) async {
    final text = query.trim();
    if (text.isEmpty) return const [];
    final key =
        's|${text.toLowerCase()}|${near?.lat.toStringAsFixed(1)},${near?.lng.toStringAsFixed(1)}';
    final cached = _cache[key];
    if (cached is List<Destination>) return cached;
    final body = await _get('/search', {
      'q': text,
      'format': 'jsonv2',
      'namedetails': '1',
      'addressdetails': '1',
      'countrycodes': 'lk',
      'limit': '10',
      if (near != null)
        'viewbox':
            '${near.lng - 0.3},${near.lat + 0.3},${near.lng + 0.3},${near.lat - 0.3}',
    });
    final results = (body as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(parseResult)
        .whereType<Destination>()
        .toList(growable: false);
    _cache[key] = results;
    return results;
  }

  /// The place at [point]: the nearest named place for a dropped pin, or at
  /// [zoom] 14 the suburb or village around it, for "Now near".
  Future<Destination?> reverse(GeoPoint point, {int zoom = 16}) async {
    final key =
        'r$zoom|${point.lat.toStringAsFixed(4)},${point.lng.toStringAsFixed(4)}';
    final cached = _cache[key];
    if (cached is Destination) return cached;
    final body = await _get('/reverse', {
      'lat': '${point.lat}',
      'lon': '${point.lng}',
      'zoom': '$zoom',
      'format': 'jsonv2',
      'namedetails': '1',
      'addressdetails': '1',
    });
    if (body is! Map<String, dynamic> || body.containsKey('error')) return null;
    final found = parseResult(body);
    if (found == null) return null;
    // Keep the pin where it was dropped, with the nearest place's names.
    final result = Destination(
      point: point,
      names: found.names,
      area: found.area,
    );
    _cache[key] = result;
    return result;
  }

  Future<Object?> _get(String path, Map<String, String> query) async {
    final last = _last;
    if (last != null) {
      final gap = _clock().difference(last);
      if (gap < const Duration(seconds: 1)) {
        await _wait(const Duration(seconds: 1) - gap);
      }
    }
    _last = _clock();
    final response = await _client.get(
      Uri.https(_host, path, query),
      headers: {'User-Agent': userAgent, 'Accept-Language': 'en'},
    );
    if (response.statusCode != 200) {
      throw NominatimException(response.statusCode);
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
  }
}

/// One Nominatim result as a destination: its names in English, Tamil and
/// Sinhala from OSM's name tags, and its suburb and town.
Destination? parseResult(Map<String, dynamic> json) {
  final lat = double.tryParse('${json['lat']}');
  final lng = double.tryParse('${json['lon']}');
  if (lat == null || lng == null) return null;
  final names = json['namedetails'] is Map
      ? (json['namedetails'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  String? pick(Object? value) =>
      value is String && value.trim().isNotEmpty ? value.trim() : null;
  final address = json['address'] is Map
      ? (json['address'] as Map).cast<String, dynamic>()
      : const <String, dynamic>{};
  final area = <String>{
    for (final part in [
      address['suburb'],
      address['city'] ?? address['town'] ?? address['village'],
    ])
      ?pick(part),
  }.join(', ');
  return Destination(
    point: GeoPoint(lat, lng),
    names: PlaceNames(
      en: pick(names['name:en']) ?? pick(json['name']),
      ta: pick(names['name:ta']),
      si: pick(names['name:si']),
    ),
    area: area.isEmpty ? null : area,
  );
}
