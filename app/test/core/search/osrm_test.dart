import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/core/search/osrm.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const fort = GeoPoint(6.9344, 79.8428);
  const hall = GeoPoint(6.9150, 79.8600);
  const lake = GeoPoint(6.9000, 79.8700);
  const road = [fort, GeoPoint(6.9250, 79.8500), hall, lake];

  test('draws the road through the towns in order, saying who asks', () async {
    final asked = <http.Request>[];
    final osrm = Osrm(
      client: MockClient((request) async {
        asked.add(request);
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {'geometry': encodePolyline(road)},
            ],
          }),
          200,
        );
      }),
    );
    expect(await osrm.road([fort, hall, lake]), road);
    final url = asked.single.url;
    expect(url.host, 'router.project-osrm.org');
    expect(
      url.path,
      '/route/v1/driving/79.84280,6.93440;79.86000,6.91500;79.87000,6.90000',
    );
    expect(url.queryParameters['overview'], 'full');
    expect(asked.single.headers['User-Agent'], Nominatim.userAgent);
  });

  test('no road: none found, a server error or no network', () async {
    Future<List<GeoPoint>?> answer(http.Response response) =>
        Osrm(client: MockClient((_) async => response)).road([fort, lake]);
    expect(await answer(http.Response('{"code":"NoRoute"}', 200)), isNull);
    expect(await answer(http.Response('busy', 503)), isNull);
    expect(await answer(http.Response('<html>', 200)), isNull);
    final offline = Osrm(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    expect(await offline.road([fort, lake]), isNull);
    // One town is no road.
    expect(await offline.road([fort]), isNull);
  });
}
