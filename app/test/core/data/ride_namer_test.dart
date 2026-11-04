import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:http/http.dart' as http;

import '../../helpers/fakes.dart';
import '../search/nominatim_test.dart' show json, uniJson;

/// Nominatim's answer around Slave Island, south of the Fort.
const slaveIslandJson = {
  'lat': '6.9270',
  'lon': '79.8510',
  'name': 'Slave Island',
  'namedetails': {
    'name': 'Slave Island',
    'name:en': 'Slave Island',
    'name:ta': 'கொம்பனித்தெரு',
  },
  'address': {'suburb': 'Slave Island', 'city': 'Colombo'},
};

void main() {
  late Workspace workspace;
  late List<Uri> asked;
  late bool offline;

  setUp(() {
    workspace = Workspace('r1', memoryDatabase(), FakeRemote());
    asked = [];
    offline = false;
  });

  tearDown(() => workspace.close());

  Nominatim nominatim() => fakeNominatim((request) async {
    if (offline) throw http.ClientException('offline');
    asked.add(request.url);
    final lat = double.parse(request.url.queryParameters['lat']!);
    return json(lat < 6.93 ? slaveIslandJson : uniJson);
  });

  RideRecord ride(String id, {RideVerdict verdict = RideVerdict.bus}) =>
      RideRecord(
        id: id,
        startedAt: DateTime.utc(2026, 1, 1, 8),
        endedAt: DateTime.utc(2026, 1, 1, 8, 30),
        verdict: verdict,
        distanceM: 2000,
        path: verdict == RideVerdict.notBus
            ? const []
            : const [GeoPoint(6.9270, 79.8510), GeoPoint(6.9344, 79.8501)],
      );

  Future<RideRecord> only() async =>
      (await workspace.rides.watch().first).single;

  test('a saved place by its name, otherwise the area around', () async {
    await workspace.places.add(
      const Destination(point: GeoPoint(6.9350, 79.8505)),
      name: 'Office',
      kind: PlaceKind.work,
    );
    await workspace.rides.save(ride('ride1'));
    await workspace.namer(nominatim()).nameMissing();

    final named = await only();
    expect(named.fromName, 'Slave Island');
    expect(named.toName, 'Office');
    expect(asked, hasLength(1));
    expect(asked.single.path, '/reverse');
    expect(asked.single.queryParameters['zoom'], '14');
    expect(await workspace.rides.unnamed(), isEmpty);
  });

  test("in the app's language", () async {
    await workspace.appSettings.setLanguage('ta');
    await workspace.rides.save(ride('ride1'));
    await workspace.namer(nominatim()).nameMissing();
    final named = await only();
    expect(named.fromName, 'கொம்பனித்தெரு');
    expect(named.toName, 'கொழும்பு கோட்டை');
  });

  test('offline, a ride waits for the next go', () async {
    await workspace.rides.save(ride('ride1'));
    offline = true;
    await workspace.namer(nominatim()).nameMissing();
    expect((await only()).fromName, isNull);
    expect(await workspace.rides.unnamed(), hasLength(1));

    offline = false;
    await workspace.namer(nominatim()).nameMissing();
    expect((await only()).toName, 'Colombo Fort');
  });

  test('leaves rides without a path alone', () async {
    await workspace.rides.save(ride('ride1', verdict: RideVerdict.notBus));
    await workspace.namer(nominatim()).nameMissing();
    expect(asked, isEmpty);
    expect((await only()).fromName, isNull);
  });
}
