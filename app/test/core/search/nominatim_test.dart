import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const uniJson = {
  'lat': '6.9344',
  'lon': '79.8501',
  'name': 'Colombo Fort',
  'namedetails': {
    'name': 'කොළඹ කොටුව Colombo Fort',
    'name:en': 'Colombo Fort',
    'name:si': 'කොළඹ කොටුව',
    'name:ta': 'கொழும்பு கோட்டை',
  },
  'address': {'suburb': 'Fort', 'city': 'Colombo'},
};

http.Response json(Object body, [int status = 200]) => http.Response.bytes(
  utf8.encode(jsonEncode(body)),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test('reads the names in each language and the area', () {
    final place = parseResult(uniJson)!;
    expect(place.point, const GeoPoint(6.9344, 79.8501));
    expect(place.names.en, 'Colombo Fort');
    expect(place.names.ta, 'கொழும்பு கோட்டை');
    expect(place.names.si, 'කොළඹ කොටුව');
    expect(place.area, 'Fort, Colombo');
  });

  test('falls back to the plain name and skips empty parts', () {
    final place = parseResult({
      'lat': '7',
      'lon': '80',
      'name': 'Bus stand',
      'address': {'town': ''},
    })!;
    expect(place.names.en, 'Bus stand');
    expect(place.names.si, isNull);
    expect(place.area, isNull);
    expect(parseResult({'lat': 'x', 'lon': '80'}), isNull);
  });

  test('searches Sri Lanka near you, says who is asking, and caches', () async {
    final requests = <http.Request>[];
    final nominatim = Nominatim(
      client: MockClient((request) async {
        requests.add(request);
        return json([uniJson]);
      }),
      wait: (_) async {},
    );
    final results = await nominatim.search(
      ' colombo fort ',
      near: const GeoPoint(6.93, 79.85),
    );
    expect(results.single.names.en, 'Colombo Fort');
    final uri = requests.single.url;
    expect(uri.path, '/search');
    expect(uri.queryParameters['q'], 'colombo fort');
    expect(uri.queryParameters['countrycodes'], 'lk');
    expect(uri.queryParameters['namedetails'], '1');
    expect(uri.queryParameters['viewbox'], isNotNull);
    expect(requests.single.headers['User-Agent'], Nominatim.userAgent);

    await nominatim.search('Colombo Fort', near: const GeoPoint(6.93, 79.85));
    expect(requests, hasLength(1));
  });

  test('waits so requests stay a second apart', () async {
    var now = DateTime(2026, 11, 3, 9);
    final waits = <Duration>[];
    final nominatim = Nominatim(
      client: MockClient((_) async => json(<Object>[])),
      clock: () => now,
      wait: (gap) async {
        waits.add(gap);
        now = now.add(gap);
      },
    );
    await nominatim.search('one');
    now = now.add(const Duration(milliseconds: 300));
    await nominatim.search('two');
    expect(waits, [const Duration(milliseconds: 700)]);
  });

  test(
    'names a dropped pin after the nearest place, keeping the pin',
    () async {
      final nominatim = Nominatim(
        client: MockClient((_) async => json(uniJson)),
        wait: (_) async {},
      );
      final pin = await nominatim.reverse(const GeoPoint(6.9342, 79.8499));
      expect(pin!.point, const GeoPoint(6.9342, 79.8499));
      expect(pin.names.si, 'කොළඹ කොටුව');
    },
  );

  test('reports a failed request', () async {
    final nominatim = Nominatim(
      client: MockClient((_) async => json({}, 503)),
      wait: (_) async {},
    );
    await expectLater(
      nominatim.search('x'),
      throwsA(isA<NominatimException>()),
    );
  });
}
