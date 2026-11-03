import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/features/home/cubit/home_cubit.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fakes.dart';

const here = GeoPoint(6.9200, 79.8550);
const uni = Destination(
  point: GeoPoint(6.9344, 79.8501),
  names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
);

void main() {
  late Workspace workspace;
  late FakeLocation location;

  setUp(() {
    workspace = Workspace('r1', memoryDatabase(), FakeRemote());
    location = FakeLocation(here: here);
  });

  tearDown(() => workspace.close());

  HomeCubit cubit({List<Object>? reverse}) => HomeCubit(
    workspace,
    location,
    fakeNominatim(
      (_) async => http.Response.bytes(
        utf8.encode(
          jsonEncode(
            reverse ??
                {
                  'lat': '6.9344',
                  'lon': '79.8501',
                  'namedetails': {
                    'name:en': 'Colombo Fort',
                    'name:si': 'කොළඹ කොටුව',
                  },
                },
          ),
        ),
        200,
      ),
    ),
  );

  test('explains once, then asks, then follows you', () async {
    final home = cubit();
    await home.start();
    expect(home.state.location, LocationStatus.explain);

    await home.continueToPermission();
    expect(location.requests, 1);
    expect(home.state.location, LocationStatus.granted);
    expect(home.state.me, here);

    location.move(const GeoPoint(6.92, 79.86));
    expect(home.state.me, const GeoPoint(6.92, 79.86));
    await home.close();
  });

  test(
    '"Not now" is remembered, and location can be asked for later',
    () async {
      final first = cubit();
      await first.start();
      await first.notNow();
      expect(first.state.location, LocationStatus.denied);
      await first.close();

      final again = cubit();
      await again.start();
      expect(again.state.location, LocationStatus.denied);
      expect(location.requests, 0);

      await again.askForLocation();
      expect(again.state.location, LocationStatus.granted);
      await again.close();
    },
  );

  test(
    'starts following straight away when location is already allowed',
    () async {
      location.access = LocationAccess.granted;
      final home = cubit();
      await home.start();
      expect(home.state.location, LocationStatus.granted);
      expect(home.state.me, here);
      await home.close();
    },
  );

  test('opens a searched place and keeps it among the recents', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    expect(home.state.destination, uni);
    await pumpEventQueue();
    expect(
      (await workspace.recents.watch().first).single.names.si,
      'කොළඹ කොටුව',
    );
    await home.close();
  });

  test('names a dropped pin after the nearest place', () async {
    final home = cubit();
    await home.start();
    final pin = home.dropPin(const GeoPoint(6.9342, 79.8499));
    expect(home.state.resolving, isTrue);
    await pin;
    expect(home.state.resolving, isFalse);
    expect(home.state.destination?.names.si, 'කොළඹ කොටුව');
    expect(home.state.destination?.point, const GeoPoint(6.9342, 79.8499));
    await home.close();
  });

  test('saves the open place, renames it and removes it', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    await home.save(name: 'Uni', kind: PlaceKind.uni);
    await pumpEventQueue();
    final saved = home.state.destination!.saved!;
    expect(saved.name, 'Uni');
    expect(home.state.places.single.kind, PlaceKind.uni);

    await home.save(name: 'Campus', kind: PlaceKind.uni);
    await pumpEventQueue();
    expect(home.state.places.single.name, 'Campus');
    expect(home.state.destination!.saved!.name, 'Campus');

    await home.removePlace(home.state.places.single);
    await pumpEventQueue();
    expect(home.state.places, isEmpty);
    expect(home.state.destination!.saved, isNull);
    await home.close();
  });

  test('recognises a saved place when it is picked again', () async {
    final home = cubit();
    await home.start();
    home.select(uni);
    await home.save(name: 'Uni', kind: PlaceKind.uni);
    await pumpEventQueue();
    home
      ..clear()
      ..select(const Destination(point: GeoPoint(6.93441, 79.85011)));
    expect(home.state.destination!.saved?.name, 'Uni');
    await home.close();
  });
}
