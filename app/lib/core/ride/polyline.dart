import 'dart:math' as math;

import 'package:hopin/core/geo/geo.dart';

/// Google's encoded polyline (precision 5): a ride's path in a few KB.
String encodePolyline(Iterable<GeoPoint> points) {
  final out = StringBuffer();
  var lastLat = 0;
  var lastLng = 0;
  for (final point in points) {
    final lat = (point.lat * 1e5).round();
    final lng = (point.lng * 1e5).round();
    _encode(lat - lastLat, out);
    _encode(lng - lastLng, out);
    lastLat = lat;
    lastLng = lng;
  }
  return out.toString();
}

List<GeoPoint> decodePolyline(String encoded) {
  final points = <GeoPoint>[];
  var index = 0;
  var lat = 0;
  var lng = 0;
  int next() {
    var shift = 0;
    var result = 0;
    int byte;
    do {
      if (index >= encoded.length) throw const FormatException('cut short');
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    return (result & 1) != 0 ? ~(result >> 1) : result >> 1;
  }

  while (index < encoded.length) {
    lat += next();
    lng += next();
    points.add(GeoPoint(lat / 1e5, lng / 1e5));
  }
  return points;
}

void _encode(int value, StringBuffer out) {
  var v = value < 0 ? ~(value << 1) : value << 1;
  while (v >= 0x20) {
    out.writeCharCode((0x20 | (v & 0x1f)) + 63);
    v >>= 5;
  }
  out.writeCharCode(v + 63);
}

/// [points] without the ones that hardly bend the line: leaving them out
/// moves it at most [toleranceM] metres (Douglas-Peucker, on a flat local
/// projection, plenty for a bus route). The ends always stay.
List<GeoPoint> thinLine(List<GeoPoint> points, {double toleranceM = 10}) {
  if (points.length < 3) return List.of(points);
  final origin = points.first;
  final east = 111320 * math.cos(origin.lat * math.pi / 180);
  const north = 110540.0;
  final xs = [for (final p in points) (p.lng - origin.lng) * east];
  final ys = [for (final p in points) (p.lat - origin.lat) * north];
  final keep = List<bool>.filled(points.length, false)
    ..first = true
    ..last = true;
  final spans = [(0, points.length - 1)];
  while (spans.isNotEmpty) {
    final (a, b) = spans.removeLast();
    var farthest = 0.0;
    var at = -1;
    for (var i = a + 1; i < b; i++) {
      final off = _offLine(xs[i], ys[i], xs[a], ys[a], xs[b], ys[b]);
      if (off > farthest) {
        farthest = off;
        at = i;
      }
    }
    if (at >= 0 && farthest > toleranceM) {
      keep[at] = true;
      spans
        ..add((a, at))
        ..add((at, b));
    }
  }
  return [
    for (var i = 0; i < points.length; i++)
      if (keep[i]) points[i],
  ];
}

/// How far (x, y) is from the segment (ax, ay) to (bx, by).
double _offLine(
  double x,
  double y,
  double ax,
  double ay,
  double bx,
  double by,
) {
  final dx = bx - ax;
  final dy = by - ay;
  final span = dx * dx + dy * dy;
  final t = span == 0
      ? 0.0
      : (((x - ax) * dx + (y - ay) * dy) / span).clamp(0.0, 1.0);
  final px = ax + t * dx - x;
  final py = ay + t * dy - y;
  return math.sqrt(px * px + py * py);
}
