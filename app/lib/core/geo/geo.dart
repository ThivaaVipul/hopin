import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// A point on the map, in degrees.
class GeoPoint extends Equatable {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  /// Great-circle distance in metres (haversine).
  double distanceTo(GeoPoint other) {
    const earth = 6371000.0;
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(other.lat - lat);
    final dLng = rad(other.lng - lng);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(lat)) *
            math.cos(rad(other.lat)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * earth * math.asin(math.min(1, math.sqrt(a)));
  }

  @override
  List<Object?> get props => [lat, lng];
}

/// Where the map starts before it knows where you are.
const colombo = GeoPoint(6.9271, 79.8612);

/// "450 m", "2.4 km", "18 km": metres under a kilometre, one decimal under ten.
({String value, bool km}) shortDistance(double metres) {
  if (metres < 1000) return (value: '${(metres / 10).round() * 10}', km: false);
  final km = metres / 1000;
  return (value: km < 10 ? km.toStringAsFixed(1) : '${km.round()}', km: true);
}
