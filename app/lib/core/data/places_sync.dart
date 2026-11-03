import 'dart:async';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';

/// Keeps the rider's saved places in step with `people/{uid}/places`.
///
/// Up: every pending row is written to the server; once the server has it and
/// the row hasn't changed since, it stops being pending. Down: changes after
/// the cursor (started a minute early, since a write's server time can
/// precede its arrival) replace local rows, except rows with a pending write
/// of this phone's, which go up first and come back.
class PlacesSync {
  PlacesSync(this._db, this._remote, this._uid);

  static const _cursorKey = 'cursor.places';
  static const _margin = 60 * 1000 * 1000;

  final HopinDatabase _db;
  final Remote _remote;
  final String _uid;
  StreamSubscription<List<RemoteDoc>>? _subscription;
  Future<void>? _running;
  bool _pushAgain = false;

  /// Told about uploads that failed; the rows stay pending.
  void Function(Object error, StackTrace stack)? onError;

  String get _collection => 'people/$_uid/places';

  Future<void> start() async {
    if (_subscription != null) return;
    final cursor = await _cursor();
    _subscription = _remote
        .changes(_collection, cursor == 0 ? 0 : cursor - _margin)
        .listen((docs) => unawaited(_apply(docs)));
    await push();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Uploads every pending row. A call while an upload is running makes it go
  /// round once more, and waits for it.
  Future<void> push() {
    if (_subscription == null) return Future.value();
    final running = _running;
    if (running != null) {
      _pushAgain = true;
      return running;
    }
    return _running = _upload().whenComplete(() => _running = null);
  }

  Future<void> _upload() async {
    do {
      _pushAgain = false;
      final pending = await (_db.select(
        _db.places,
      )..where((p) => p.pendingSince.isNotNull())).get();
      for (final row in pending) {
        try {
          await _remote.put('$_collection/${row.id}', {
            'name': row.name,
            'kind': row.kind,
            'lat': row.lat,
            'lng': row.lng,
            'placeEn': row.placeEn,
            'placeTa': row.placeTa,
            'placeSi': row.placeSi,
          }, deleted: row.deletedAt != null);
        } on Object catch (error, stack) {
          // Refused or unreachable: the row stays pending and goes up with
          // the next change or the next start.
          onError?.call(error, stack);
          return;
        }
        await (_db.update(_db.places)..where(
              (p) =>
                  p.id.equals(row.id) &
                  p.pendingSince.equals(row.pendingSince!),
            ))
            .write(const PlacesCompanion(pendingSince: Value(null)));
      }
    } while (_pushAgain);
  }

  Future<void> _apply(List<RemoteDoc> docs) async {
    if (docs.isEmpty) return;
    var newest = await _cursor();
    await _db.transaction(() async {
      for (final doc in docs) {
        if (doc.updatedAt > newest) newest = doc.updatedAt;
        final local = await (_db.select(
          _db.places,
        )..where((p) => p.id.equals(doc.id))).getSingleOrNull();
        if (local?.pendingSince != null) continue;
        final d = doc.data;
        await _db
            .into(_db.places)
            .insertOnConflictUpdate(
              PlacesCompanion.insert(
                id: doc.id,
                name: d['name'] as String? ?? '',
                kind: d['kind'] as String? ?? 'other',
                lat: (d['lat'] as num?)?.toDouble() ?? 0,
                lng: (d['lng'] as num?)?.toDouble() ?? 0,
                placeEn: Value(d['placeEn'] as String?),
                placeTa: Value(d['placeTa'] as String?),
                placeSi: Value(d['placeSi'] as String?),
                updatedAt: doc.updatedAt,
                deletedAt: Value(d['deletedAt'] as int?),
                pendingSince: const Value(null),
              ),
            );
      }
      await _db
          .into(_db.settings)
          .insertOnConflictUpdate(
            SettingsCompanion.insert(key: _cursorKey, value: '$newest'),
          );
    });
  }

  Future<int> _cursor() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_cursorKey))).getSingleOrNull();
    return int.tryParse(row?.value ?? '') ?? 0;
  }
}
