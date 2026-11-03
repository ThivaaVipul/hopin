import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';

void main() {
  test('measures great-circle distances', () {
    const kandy = GeoPoint(7.2906, 80.6337);
    expect(colombo.distanceTo(kandy), closeTo(94000, 1500));
    expect(colombo.distanceTo(colombo), 0);
  });

  test('writes distances the short way', () {
    expect(shortDistance(437), (value: '440', km: false));
    expect(shortDistance(995), (value: '1000', km: false));
    expect(shortDistance(2440), (value: '2.4', km: true));
    expect(shortDistance(18400), (value: '18', km: true));
  });
}
