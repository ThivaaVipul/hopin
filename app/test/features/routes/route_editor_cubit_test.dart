import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/route_editor_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late HopinDatabase db;
  late RoutesRepository routes;
  late FakeRoads roads;
  const fort = RouteTown(GeoPoint(6.9344, 79.8428), PlaceNames(en: 'Fort'));
  const hall = RouteTown(GeoPoint(6.9150, 79.8600), PlaceNames(en: 'Hall'));
  const lake = RouteTown(GeoPoint(6.9000, 79.8700), PlaceNames(en: 'Lake'));

  setUp(() {
    db = memoryDatabase();
    routes = RoutesRepository(db, uid: 'r1');
    roads = FakeRoads();
  });

  tearDown(() => db.close());

  test(
    'draws the road once both ends are picked, and again as towns change',
    () async {
      final editor = RouteEditorCubit(routes, roads.osrm)..setNumber('138');
      await editor.setFrom(fort);
      expect(roads.asked, isEmpty);
      expect(editor.state.canSave, isFalse);
      await editor.setTo(lake);
      expect(editor.state.road, [fort.point, lake.point]);
      expect(editor.state.canSave, isTrue);
      await editor.addTown(hall);
      expect(editor.state.road, [fort.point, hall.point, lake.point]);
      await editor.removeTown(0);
      expect(editor.state.road, [fort.point, lake.point]);
      expect(roads.asked, hasLength(3));
      await editor.close();
    },
  );

  test('no network: no road and no Save until it draws', () async {
    roads.offline = true;
    final editor = RouteEditorCubit(routes, roads.osrm)..setNumber('138');
    await editor.setFrom(fort);
    await editor.setTo(lake);
    expect(editor.state.failed, isTrue);
    expect(editor.state.road, isNull);
    expect(editor.state.canSave, isFalse);
    roads.offline = false;
    await editor.drawAgain();
    expect(editor.state.failed, isFalse);
    expect(editor.state.canSave, isTrue);
    await editor.close();
  });

  test('saves a new route, and changes one already added', () async {
    final editor = RouteEditorCubit(routes, roads.osrm)..setNumber('138');
    await editor.setFrom(fort);
    await editor.setTo(lake);
    await editor.save();
    expect(editor.state.saved, isTrue);
    await editor.close();
    final directions = await routes.watch().first;
    expect(directions.map((d) => d.number), ['138', '138']);

    final routeId = directions.first.routeId;
    final change = RouteEditorCubit(routes, roads.osrm, routeId: routeId);
    expect(change.state.loaded, isFalse);
    await change.start();
    expect(change.state.loaded, isTrue);
    expect(
      (change.state.number, change.state.from, change.state.to),
      ('138', fort, lake),
    );
    // Its road comes with it: Save at once.
    expect(change.state.canSave, isTrue);
    await change.addTown(hall);
    await change.save();
    await change.close();
    expect((await routes.watchHand(routeId).first)?.via, [hall]);
  });
}
