import 'package:geolocator/geolocator.dart';
import 'package:hopin/core/geo/geo.dart';

enum LocationAccess {
  granted,
  denied,

  /// Refused with "don't ask again": only the app's settings can change it.
  blocked,

  /// The phone's location is switched off.
  off,
}

/// Where the phone is, "while using the app" (M1a). Background location joins
/// in M1b.
abstract interface class LocationService {
  Future<LocationAccess> check();

  /// Shows Android's permission popup (or the settings, once blocked).
  Future<LocationAccess> request();

  Future<GeoPoint?> current();

  Stream<GeoPoint> positions();
}

class GeolocatorLocation implements LocationService {
  static const _settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  @override
  Future<LocationAccess> check() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.off;
    return _access(await Geolocator.checkPermission());
  }

  @override
  Future<LocationAccess> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
      return check();
    }
    final now = await Geolocator.checkPermission();
    if (now == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return check();
    }
    return _access(await Geolocator.requestPermission());
  }

  @override
  Future<GeoPoint?> current() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(position.latitude, position.longitude);
    } on Exception {
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : GeoPoint(last.latitude, last.longitude);
    }
  }

  @override
  Stream<GeoPoint> positions() => Geolocator.getPositionStream(
    locationSettings: _settings,
  ).map((position) => GeoPoint(position.latitude, position.longitude));

  LocationAccess _access(LocationPermission permission) => switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationAccess.granted,
    LocationPermission.deniedForever => LocationAccess.blocked,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => LocationAccess.denied,
  };
}
