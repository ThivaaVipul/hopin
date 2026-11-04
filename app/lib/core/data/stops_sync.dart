import 'dart:async';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';

/// A pooled collection both riders read (docs/PLAN.md, Sharing and stops),
/// kept in step like the places: local changes go up, marked pending until
/// the server has them; the server's come down after the cursor.
abstract class _PooledSync {
  _PooledSync(this._db, this._remote, this._collection, this._cursorKey);

  static const _margin = 60 * 1000 * 1000;

  final HopinDatabase _db;
  final Remote _remote;
  final String _collection;
  final String _cursorKey;
  StreamSubscription<List<RemoteDoc>>? _subscription;
  Future<void>? _running;
  bool _pushAgain = false;

  /// Told about uploads that failed; the rows stay pending.
  void Function(Object error, StackTrace stack)? onError;

  /// The rows waiting to go up: id, data, deleted (null when it can't be),
  /// and the pending mark they carry.
  Future<List<(String, Map<String, Object?>, bool?, int)>> _pending();

  Future<void> _sent(String id, int pendingSince);

  /// Takes the server's document unless a local change is still going up.
  Future<void> _take(RemoteDoc doc);

  Future<void> start() async {
    if (_subscription != null) return;
    final cursor = await _cursor();
    _subscription = _remote
        .changes(_collection, cursor == 0 ? 0 : cursor - _margin)
        .listen(
          (docs) => unawaited(_apply(docs)),
          onError: (Object error, StackTrace stack) {
            onError?.call(error, stack);
            unawaited(_subscription?.cancel());
            _subscription = null;
          },
        );
    await push();
  }

  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

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
      for (final (id, data, deleted, since) in await _pending()) {
        try {
          await _remote.put('$_collection/$id', data, deleted: deleted);
        } on Object catch (error, stack) {
          onError?.call(error, stack);
          return;
        }
        await _sent(id, since);
      }
    } while (_pushAgain);
  }

  Future<void> _apply(List<RemoteDoc> docs) async {
    if (docs.isEmpty) return;
    var newest = await _cursor();
    await _db.transaction(() async {
      for (final doc in docs) {
        if (doc.updatedAt > newest) newest = doc.updatedAt;
        await _take(doc);
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

/// The pool of bus rides' halts (`halts/{rideId}`): this rider's go up,
/// both riders' come down.
class HaltsSync extends _PooledSync {
  HaltsSync(HopinDatabase db, Remote remote)
    : super(db, remote, 'halts', 'cursor.halts');

  @override
  Future<List<(String, Map<String, Object?>, bool?, int)>> _pending() async => [
    for (final row in await (_db.select(
      _db.pooledHalts,
    )..where((r) => r.pendingSince.isNotNull())).get())
      (
        row.rideId,
        {'uid': row.uid, 'points': row.points},
        row.deletedAt != null,
        row.pendingSince!,
      ),
  ];

  @override
  Future<void> _sent(String id, int pendingSince) =>
      (_db.update(_db.pooledHalts)..where(
            (r) => r.rideId.equals(id) & r.pendingSince.equals(pendingSince),
          ))
          .write(const PooledHaltsCompanion(pendingSince: Value(null)));

  @override
  Future<void> _take(RemoteDoc doc) async {
    final local = await (_db.select(
      _db.pooledHalts,
    )..where((r) => r.rideId.equals(doc.id))).getSingleOrNull();
    if (local?.pendingSince != null) return;
    final d = doc.data;
    final uid = d['uid'];
    if (uid is! String) return;
    await _db
        .into(_db.pooledHalts)
        .insertOnConflictUpdate(
          PooledHaltsCompanion.insert(
            rideId: doc.id,
            uid: uid,
            points: d['points'] as String? ?? '',
            updatedAt: doc.updatedAt,
            deletedAt: Value(d['deletedAt'] as int?),
            pendingSince: const Value(null),
          ),
        );
  }
}

/// The riders' renames and removals of learned stops (`stopNotes/{id}`).
class StopNotesSync extends _PooledSync {
  StopNotesSync(HopinDatabase db, Remote remote)
    : super(db, remote, 'stopNotes', 'cursor.stopNotes');

  @override
  Future<List<(String, Map<String, Object?>, bool?, int)>> _pending() async => [
    for (final row in await (_db.select(
      _db.stopNotes,
    )..where((r) => r.pendingSince.isNotNull())).get())
      (
        row.id,
        {
          'lat': row.lat,
          'lng': row.lng,
          'name': row.name,
          'removed': row.removed,
          'by': row.by,
        },
        null,
        row.pendingSince!,
      ),
  ];

  @override
  Future<void> _sent(String id, int pendingSince) =>
      (_db.update(_db.stopNotes)..where(
            (r) => r.id.equals(id) & r.pendingSince.equals(pendingSince),
          ))
          .write(const StopNotesCompanion(pendingSince: Value(null)));

  @override
  Future<void> _take(RemoteDoc doc) async {
    final local = await (_db.select(
      _db.stopNotes,
    )..where((r) => r.id.equals(doc.id))).getSingleOrNull();
    if (local?.pendingSince != null) return;
    final d = doc.data;
    final lat = d['lat'];
    final lng = d['lng'];
    final by = d['by'];
    if (lat is! num || lng is! num || by is! String) return;
    await _db
        .into(_db.stopNotes)
        .insertOnConflictUpdate(
          StopNotesCompanion.insert(
            id: doc.id,
            lat: lat.toDouble(),
            lng: lng.toDouble(),
            name: Value(d['name'] as String?),
            removed: Value(d['removed'] == true),
            by: by,
            updatedAt: doc.updatedAt,
            pendingSince: const Value(null),
          ),
        );
  }
}
