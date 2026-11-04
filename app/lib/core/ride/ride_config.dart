import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';

/// What the ride service needs when it wakes for a ride with Hopin closed
/// (docs/PLAN.md, Ride detection): the places for the "On a bus?" buttons,
/// the alert stages and the language. The app keeps it up to date.
class RideConfig extends Equatable {
  const RideConfig({
    this.places = const [],
    this.stages = defaultStages,
    this.language = 'en',
  });

  /// The first two saved places, in the rider's order.
  final List<SavedPlace> places;
  final List<GuideStage> stages;
  final String language;

  static const buttons = 2;

  /// A guide to [place], as a place button starts it.
  GuideRide guideTo(SavedPlace place) => GuideRide(
    to: place.point,
    title: place.name,
    names: place.names,
    stages: stages,
    language: language,
    share: place.shareRides,
  );

  Map<String, Object?> toJson() => {
    'places': [
      for (final place in places.take(buttons))
        {
          'id': place.id,
          'name': place.name,
          'kind': place.kind.name,
          'lat': place.point.lat,
          'lng': place.point.lng,
          'en': place.names.en,
          'ta': place.names.ta,
          'si': place.names.si,
          'share': place.shareRides,
        },
    ],
    'stages': [for (final stage in stages) stage.toJson()],
    'language': language,
  };

  static RideConfig fromJson(Object? json) {
    if (json is! Map) return const RideConfig();
    String? text(Map<dynamic, dynamic> map, String key) =>
        map[key] is String ? map[key] as String : null;
    return RideConfig(
      places: [
        if (json['places'] case final List<Object?> list)
          for (final place in list)
            if (place is Map &&
                place['lat'] is num &&
                place['lng'] is num &&
                text(place, 'name') != null)
              SavedPlace(
                id: text(place, 'id') ?? '',
                name: text(place, 'name')!,
                kind:
                    PlaceKind.values.asNameMap()[place['kind']] ??
                    PlaceKind.other,
                point: GeoPoint(
                  (place['lat'] as num).toDouble(),
                  (place['lng'] as num).toDouble(),
                ),
                names: PlaceNames(
                  en: text(place, 'en'),
                  ta: text(place, 'ta'),
                  si: text(place, 'si'),
                ),
                shareRides: place['share'] == true,
              ),
      ],
      stages: stagesFromJson(json['stages']),
      language: text(json, 'language') == 'ta' ? 'ta' : 'en',
    );
  }

  @override
  List<Object?> get props => [places, stages, language];
}
