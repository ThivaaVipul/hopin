import 'dart:convert';

import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:http/http.dart' as http;

/// Roads along real roads from OSRM's public server (docs/PLAN.md, Which
/// bus), for a route added by hand: one request each time its towns change,
/// within the server's light-use policy, with an identifying user agent.
class Osrm {
  Osrm({http.Client? client}) : _client = client ?? http.Client();

  static const _base = 'https://router.project-osrm.org/route/v1/driving/';

  final http.Client _client;

  /// The road through [points] in order, thinned; null when there is none or
  /// the server can't be reached.
  Future<List<GeoPoint>?> road(List<GeoPoint> points) async {
    if (points.length < 2) return null;
    final coordinates = [
      for (final point in points)
        '${point.lng.toStringAsFixed(5)},${point.lat.toStringAsFixed(5)}',
    ].join(';');
    final http.Response response;
    try {
      response = await _client.get(
        Uri.parse('$_base$coordinates?overview=full&geometries=polyline'),
        headers: {'User-Agent': Nominatim.userAgent},
      );
    } on Exception {
      return null;
    }
    if (response.statusCode != 200) return null;
    try {
      if (jsonDecode(response.body) case {
        'code': 'Ok',
        'routes': [{'geometry': final String geometry}, ...],
      }) {
        return thinLine(decodePolyline(geometry));
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}
