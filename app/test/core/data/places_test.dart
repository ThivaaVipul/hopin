import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/places_repository.dart';
import 'package:hopin/core/data/places_sync.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';

import '../../helpers/fakes.dart';

const uni = Destination(
  point: GeoPoint(6.9344, 79.8501),
  names: PlaceNames(en: 'Colombo Fort', si: 'කොළඹ කොටුව'),
);

void main() {
  late HopinDatabase db;
  late PlacesRepository places;
  late FakeRemote remote;
  late PlacesSync sync;
  const collection = 'people/r1/places';

  setUp(() {
    db = memoryDatabase();
    places = PlacesRepository(db);
    remote = FakeRemote();
    sync = PlacesSync(db, remote, 'r1');
    places.onChange = sync.push;
  });

  tearDown(() async {
    await sync.stop();
    await db.close();
  });

  Future<List<PlaceRow>> rows() => db.select(db.places).get();

  test(
    'keeps places in kind order, then by name, without the removed',
    () async {
      await places.add(uni, name: 'Uni', kind: PlaceKind.uni);
      final home = await places.add(
        const Destination(point: GeoPoint(6.9, 79.9)),
        name: 'Home',
        kind: PlaceKind.home,
      );
      await places.add(
        const Destination(point: GeoPoint(7, 80)),
        name: 'Aunt',
        kind: PlaceKind.other,
      );
      expect((await places.watch().first).map((p) => p.name), [
        'Home',
        'Uni',
        'Aunt',
      ]);

      await places.remove(home.id);
      expect((await places.watch().first).map((p) => p.name), ['Uni', 'Aunt']);
    },
  );

  test('marks every local change pending until the server has it', () async {
    final place = await places.add(uni, name: 'Uni', kind: PlaceKind.uni);
    expect((await rows()).single.pendingSince, isNotNull);
    expect(place.names.si, 'කොළඹ කොටුව');
    expect(
      remote.puts,
      isEmpty,
      reason: 'nothing goes up before the sync starts',
    );

    await sync.start();
    expect(remote.puts.single.$1, '$collection/${place.id}');
    expect(remote.puts.single.$2, containsPair('placeSi', 'කොළඹ කොටුව'));
    expect(remote.puts.single.$3, isFalse);
    expect((await rows()).single.pendingSince, isNull);
  });

  test('sends a removal as a marked deletion', () async {
    await sync.start();
    final place = await places.add(uni, name: 'Uni', kind: PlaceKind.uni);
    await places.remove(place.id);
    await sync.push();
    expect(remote.puts.last.$3, isTrue);
  });

  test('a removal on the same clock tick as an upload still goes up', () async {
    // A coarse clock gives both changes one time; the upload of the first
    // must not count for the second.
    final frozen = PlacesRepository(db, clock: () => DateTime.utc(2026))
      ..onChange = sync.push;
    await sync.start();
    remote.hold = Completer<void>();
    final place = await frozen.add(uni, name: 'Uni', kind: PlaceKind.uni);
    while (remote.waiting == 0) {
      await pumpEventQueue();
    }
    await frozen.remove(place.id);
    remote.hold!.complete();
    await sync.push();
    expect(remote.puts.last.$3, isTrue);
    expect((await rows()).single.pendingSince, isNull);
  });

  test('keeps a change pending while offline, and sends it later', () async {
    await sync.start();
    remote.offline = true;
    final errors = <Object>[];
    sync.onError = (error, _) => errors.add(error);
    await places.add(uni, name: 'Uni', kind: PlaceKind.uni);
    await sync.push();
    expect(errors, isNotEmpty);
    expect((await rows()).single.pendingSince, isNotNull);

    remote.offline = false;
    await sync.push();
    expect((await rows()).single.pendingSince, isNull);
  });

  test("takes the server's places and moves the cursor", () async {
    await sync.start();
    remote.push(collection, [
      const RemoteDoc('p1', {
        'name': 'Campus',
        'kind': 'uni',
        'lat': 6.9344,
        'lng': 79.8501,
        'placeEn': 'Colombo Fort',
        'placeTa': null,
        'placeSi': null,
        'deletedAt': null,
      }, 5000000000),
    ]);
    await pumpEventQueue();
    expect((await places.watch().first).single.name, 'Campus');

    await sync.stop();
    await sync.start();
    expect(remote.queried.last, (collection, 5000000000 - 60000000));
  });

  test("doesn't let the server overwrite a change still going up", () async {
    final place = await places.add(uni, name: 'Uni', kind: PlaceKind.uni);
    remote.offline = true;
    await sync.start();
    remote.push(collection, [
      RemoteDoc(place.id, const {
        'name': 'Old name',
        'kind': 'uni',
        'lat': 6.9344,
        'lng': 79.8501,
      }, 1),
    ]);
    await pumpEventQueue();
    expect((await rows()).single.name, 'Uni');
  });

  test('recents keep the newest six, once each', () async {
    final recents = RecentsRepository(db);
    for (var i = 0; i < 8; i++) {
      await recents.add(
        Destination(
          point: GeoPoint(7 + i / 100, 80),
          names: PlaceNames(en: 'Stop $i'),
        ),
      );
    }
    await recents.add(
      const Destination(
        point: GeoPoint(7.03, 80),
        names: PlaceNames(en: 'Stop 3'),
      ),
    );
    final list = await recents.watch().first;
    expect(list, hasLength(6));
    expect(list.first.names.en, 'Stop 3');
    expect(list.map((d) => d.names.en), isNot(contains('Stop 0')));
  });
}
