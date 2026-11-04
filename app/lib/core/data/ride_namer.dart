import 'package:hopin/core/data/app_settings.dart';
import 'package:hopin/core/data/places_repository.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';

/// Names a ride's start and end (docs/PLAN.md, Rides page): your saved place
/// within about 300 m, otherwise the area around it from Nominatim, in the
/// app's language. A ride it can't name now (offline, say) waits for the
/// next go: when Hopin keeps a ride, and when the Rides page opens.
class RideNamer {
  RideNamer({
    required this._rides,
    required this._places,
    required this._settings,
    required this._nominatim,
  });

  static const nearPlace = 300.0;

  /// The rules' longest name (firebase/firestore.rules, rides).
  static const longest = 200;

  final RidesRepository _rides;
  final PlacesRepository _places;
  final AppSettings _settings;
  final Nominatim _nominatim;
  Future<void>? _running;

  /// Names every ride still unnamed, one go at a time.
  Future<void> nameMissing() =>
      _running ??= _nameAll().whenComplete(() => _running = null);

  Future<void> _nameAll() async {
    final rides = await _rides.unnamed();
    if (rides.isEmpty) return;
    final language = await _settings.language();
    final places = await _places.watch().first;
    for (final ride in rides) {
      final String? from;
      final String? to;
      try {
        from = ride.fromName ?? await _name(ride.path.first, places, language);
        to = ride.toName ?? await _name(ride.path.last, places, language);
      } on Exception {
        // Offline or turned away: the rest wait for the next go.
        return;
      }
      await _rides.setNames(ride.id, from: from, to: to);
    }
  }

  Future<String?> _name(
    GeoPoint point,
    List<SavedPlace> places,
    String language,
  ) async {
    SavedPlace? nearest;
    var best = nearPlace;
    for (final place in places) {
      final away = point.distanceTo(place.point);
      if (away <= best) {
        best = away;
        nearest = place;
      }
    }
    if (nearest != null) return _fit(nearest.name);
    final around = await _nominatim.reverse(point, zoom: 14);
    final name = around?.names.inLanguage(language) ?? around?.area;
    return name == null || name.trim().isEmpty ? null : _fit(name.trim());
  }

  static String _fit(String name) =>
      name.length <= longest ? name : name.substring(0, longest);
}
