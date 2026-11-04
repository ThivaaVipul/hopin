import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';

/// The last few destinations, on this phone only (docs/PLAN.md, Home and places).
class RecentsRepository {
  RecentsRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  static const keep = 6;

  final HopinDatabase _db;
  final DateTime Function() _clock;

  Stream<List<Destination>> watch() {
    final query = _db.select(_db.recents)
      ..orderBy([(r) => OrderingTerm.desc(r.usedAt)])
      ..limit(keep);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          Destination(
            point: GeoPoint(row.lat, row.lng),
            names: PlaceNames(
              en: row.placeEn,
              ta: row.placeTa,
              si: row.placeSi,
            ),
            area: row.area,
          ),
      ],
    );
  }

  /// Puts [destination] first, keeping the newest [keep].
  Future<void> add(Destination destination) => _db.transaction(() async {
    final p = destination.point;
    await _db
        .into(_db.recents)
        .insertOnConflictUpdate(
          RecentsCompanion.insert(
            key: '${p.lat.toStringAsFixed(4)},${p.lng.toStringAsFixed(4)}',
            lat: p.lat,
            lng: p.lng,
            placeEn: Value(destination.names.en),
            placeTa: Value(destination.names.ta),
            placeSi: Value(destination.names.si),
            area: Value(destination.area),
            usedAt: _clock().microsecondsSinceEpoch,
          ),
        );
    final keepKeys = (_db.selectOnly(_db.recents)
      ..addColumns([_db.recents.key])
      ..orderBy([OrderingTerm.desc(_db.recents.usedAt)])
      ..limit(keep));
    await (_db.delete(
      _db.recents,
    )..where((r) => r.key.isNotInQuery(keepKeys))).go();
  });
}

/// This phone's small choices (docs/ARCHITECTURE.md, Local database and sync).
class SettingsStore {
  SettingsStore(this._db);

  final HopinDatabase _db;

  Future<String?> read(String key) async => (await (_db.select(
    _db.settings,
  )..where((s) => s.key.equals(key))).getSingleOrNull())?.value;

  Stream<String?> watch(String key) =>
      (_db.select(_db.settings)..where((s) => s.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value)
          .distinct();

  Future<void> remove(String key) =>
      (_db.delete(_db.settings)..where((s) => s.key.equals(key))).go();

  Future<void> write(String key, String value) => _db
      .into(_db.settings)
      .insertOnConflictUpdate(SettingsCompanion.insert(key: key, value: value));

  static const locationExplained = 'card.location';

  /// The card before Android's notification popup, at the first Start.
  static const notificationsExplained = 'card.notifications';

  /// Android's background popup and the maker's steps, at the first Start.
  static const batteryExplained = 'card.battery';

  /// The one-time card offering ride detection (M1b).
  static const detectionOffered = 'card.detection';
}
