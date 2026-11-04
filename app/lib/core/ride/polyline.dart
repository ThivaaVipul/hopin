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
