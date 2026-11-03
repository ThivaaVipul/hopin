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

  /// Called after every local change (the sync uploads pending rows).
  void Function()? onChange;

  Stream<List<SavedPlace>> watch() {
    final query = _db.select(_db.places)..where((p) => p.deletedAt.isNull());
    return query.watch().map((rows) {
      final places = rows.map(placeFromRow).toList()
        ..sort((a, b) {
          final byKind = a.kind.index.compareTo(b.kind.index);
          return byKind != 0
              ? byKind
              : a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
      return places;
    });
  }

  /// Saves a new place for [destination] and returns it.
  Future<SavedPlace> add(
    Destination destination, {
    required String name,
    required PlaceKind kind,
  }) async {
    final place = SavedPlace(
      id: newId(),
      name: name,
      kind: kind,
      point: destination.point,
      names: destination.names,
    );
    await _write(place);
    return place;
  }

  Future<void> update(SavedPlace place) => _write(place);

  Future<void> remove(String id) async {
    final now = _clock().microsecondsSinceEpoch;
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
    final now = _clock().microsecondsSinceEpoch;
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
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
    onChange?.call();
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
);
