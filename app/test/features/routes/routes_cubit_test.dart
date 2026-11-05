import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';

RouteDirection direction(
  String id,
  String number, {
  String board = 'North',
  String origin = 'South',
  List<String> also = const [],
}) => RouteDirection(
  routeId: id,
  source: RouteSource.osm,
  number: number,
  also: also,
  board: PlaceNames(en: board),
  origin: PlaceNames(en: origin),
);

void main() {
  test('routes come in number order, each with its directions', () {
    final routes = groupRoutes([
      for (final d in [
        direction('osm:3', 'CM03'),
        direction('osm:2', '15-87'),
        direction('osm:1', '2'),
        direction('osm:2', '15-87', board: 'South', origin: 'North'),
        direction('osm:4', '138'),
      ])
        NotedDirection(d),
    ]);
    expect(routes.map((r) => r.number), ['2', '15-87', '138', 'CM03']);
    expect(routes[1].directions, hasLength(2));
  });

  test('a number finds the routes that carry it, as on the bus', () {
    final route = KnownRoute([
      NotedDirection(direction('ntc:1', '15-87', also: ['15-1'])),
    ]);
    expect(carriesNumber(route, ''), isTrue);
    expect(carriesNumber(route, '15'), isTrue);
    expect(carriesNumber(route, '15/8'), isTrue);
    expect(carriesNumber(route, '15-1'), isTrue);
    expect(carriesNumber(route, '87'), isFalse);
  });

  test("both ends read as the boards do, a rider's lines and all", () {
    final there = direction('osm:9', '9');
    final back = direction('osm:9', '9', board: 'South', origin: 'North');
    final route = KnownRoute([
      NotedDirection(there),
      NotedDirection(
        back,
        RouteNote(
          route: 'osm:9',
          direction: back.noteKey,
          at: DateTime.utc(2026, 11, 5),
          board: const PlaceNames(ta: 'தெற்கு'),
        ),
      ),
    ]);
    expect(route.from, const PlaceNames(en: 'South', ta: 'தெற்கு'));
    // One way only: its own start.
    expect(KnownRoute([NotedDirection(there)]).from, there.origin);
  });
}
