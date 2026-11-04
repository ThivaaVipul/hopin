import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_config.dart';

const fort = SavedPlace(
  id: 'p1',
  name: 'Fort',
  kind: PlaceKind.other,
  point: GeoPoint(6.9344, 79.8501),
  names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
);

void main() {
  test('survives the trip to the ride service', () {
    const config = RideConfig(
      places: [fort],
      stages: [GuideStage(700, AlertPattern.heartbeat)],
      language: 'ta',
    );
    expect(RideConfig.fromJson(config.toJson()), config);
    expect(RideConfig.fromJson('nope'), const RideConfig());
  });

  test('keeps two places at most', () {
    final config = RideConfig(
      places: [
        for (var i = 0; i < 4; i++)
          SavedPlace(
            id: 'p$i',
            name: 'Place $i',
            kind: PlaceKind.other,
            point: const GeoPoint(6.9, 79.85),
          ),
      ],
    );
    expect(RideConfig.fromJson(config.toJson()).places, hasLength(2));
  });

  test('a place button guides there with your stages and language', () {
    const config = RideConfig(
      places: [fort],
      stages: [GuideStage(700, AlertPattern.heartbeat)],
      language: 'ta',
    );
    final ride = config.guideTo(fort);
    expect(ride.to, fort.point);
    expect(ride.title, 'Fort');
    expect(ride.names.si, 'කොළඹ කොටුව');
    expect(ride.stages, config.stages);
    expect(ride.language, 'ta');
  });

  test('a place shared by itself starts its guide shared', () {
    final shared = fort.copyWith(shareRides: true);
    final config = RideConfig(places: [shared]);
    expect(config.guideTo(shared).share, isTrue);
    expect(config.guideTo(fort).share, isFalse);
    final back = RideConfig.fromJson(config.toJson());
    expect(back.places.single.shareRides, isTrue);
    final ride = config.guideTo(shared);
    expect(GuideRide.fromJson(ride.toJson()), ride);
  });
}
