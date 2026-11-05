import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/polyline.dart';

void main() {
  test('a thinned line keeps its corners and drops what hardly bends it', () {
    final line = [
      // North for about 2.2 km, a point every 110 m, wobbling by 2 m.
      for (var i = 0; i <= 20; i++)
        GeoPoint(6.90 + i * 0.001, 79.85 + (i.isEven ? 0 : 0.00002)),
      // Then east.
      const GeoPoint(6.92, 79.86),
    ];
    final thin = thinLine(line);
    expect(thin, [line.first, line[20], line.last]);
    // A wobble wider than the tolerance stays.
    expect(thinLine(line, toleranceM: 1), hasLength(greaterThan(3)));
    expect(thinLine(line.sublist(0, 2)), line.sublist(0, 2));
  });
}
