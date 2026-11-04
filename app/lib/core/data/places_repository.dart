import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';

/// Saved places. Screens read the local database; every change is written
/// there first, marked pending, and [onChange] lets the sync upload it.
class PlacesRepository {
  PlacesRepository(this._db, {DateTime Function()? clock, Random? random})
    : _clock = clock ?? DateTime.now,
      _random = random ?? Random.secure();

  final HopinDatabase _db;
  final DateTime Function() _clock;
  final Random _random;
  var _lastStamp = 0;

  /// Called after every local change (the sync uploads pending rows).
  void Function()? onChange;

  Stream<List<SavedPlace>> watch() {
    final query = _db.select(_db.places)..where((p) => p.deletedAt.isNull());
    return query.watch().map((rows) {
      final sorted = [...rows]
        ..sort((a, b) {
          final byOrder = a.position.compareTo(b.position);
          if (byOrder != 0) return byOrder;
          final byKind = (PlaceKind.values.asNameMap()[a.kind]?.index ?? 9)
              .compareTo(PlaceKind.values.asNameMap()[b.kind]?.index ?? 9);
          return byKind != 0
              ? byKind
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return sorted.map(placeFromRow).toList();
    });
  }

  /// Saves a new place for [destination] and returns it.
  Future<SavedPlace> add(
    Destination destination, {
    required String name,
    required PlaceKind kind,
    bool shareRides = false,
  }) async {
    final place = SavedPlace(
      id: newId(),
      name: name,
      kind: kind,
      shareRides: shareRides,
      point: destination.point,
      names: destination.names,
    );
    await _write(place);
    return place;
  }

  Future<void> update(SavedPlace place) => _write(place);

  /// Puts the places in [order], as the rider dragged them.
  Future<void> reorder(List<SavedPlace> order) async {
    await _db.transaction(() async {
      for (final (index, place) in order.indexed) {
        final now = _stamp();
        await (_db.update(_db.places)..where(
              (p) => p.id.equals(place.id) & p.position.equals(index).not(),
            ))
            .write(
              PlacesCompanion(
                position: Value(index),
                updatedAt: Value(now),
                pendingSince: Value(now),
              ),
            );
      }
    });
    onChange?.call();
  }

  Future<void> remove(String id) async {
    final now = _stamp();
    await (_db.update(_db.places)..where((p) => p.id.equals(id))).write(
      PlacesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        pendingSince: Value(now),
      ),
    );
    onChange?.call();
  }

  Future<void> _write(SavedPlace place) async {
    final now = _stamp();
    final existing = await (_db.select(
      _db.places,
    )..where((p) => p.id.equals(place.id))).getSingleOrNull();
    final last = await (_db.selectOnly(
      _db.places,
    )..addColumns([_db.places.position.max()])).getSingle();
    final position =
        existing?.position ?? (last.read(_db.places.position.max()) ?? -1) + 1;
    await _db
        .into(_db.places)
        .insertOnConflictUpdate(
          PlacesCompanion.insert(
            id: place.id,
            name: place.name,
            kind: place.kind.name,
            lat: place.point.lat,
            lng: place.point.lng,
            placeEn: Value(place.names.en),
            placeTa: Value(place.names.ta),
            placeSi: Value(place.names.si),
            position: Value(position),
            shareRides: Value(place.shareRides),
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
    onChange?.call();
  }

  /// When a change was made, in microseconds, and always after the change
  /// before it. The sync clears a row's pending mark only while the row still
  /// carries the stamp it uploaded, so two changes on one tick of a coarse
  /// clock must not share a stamp.
  int _stamp() {
    final now = _clock().microsecondsSinceEpoch;
    return _lastStamp = now > _lastStamp ? now : _lastStamp + 1;
  }

  /// A Firestore-style random ID, made on the phone so places work offline.
  String newId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    return String.fromCharCodes(
      Iterable.generate(
        20,
        (_) => chars.codeUnitAt(_random.nextInt(chars.length)),
      ),
    );
  }
}

SavedPlace placeFromRow(PlaceRow row) => SavedPlace(
  id: row.id,
  name: row.name,
  kind: PlaceKind.values.asNameMap()[row.kind] ?? PlaceKind.other,
  point: GeoPoint(row.lat, row.lng),
  names: PlaceNames(en: row.placeEn, ta: row.placeTa, si: row.placeSi),
  shareRides: row.shareRides,
);
