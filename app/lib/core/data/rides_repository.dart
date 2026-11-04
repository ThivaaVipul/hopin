import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/ride/ride_record.dart';

/// The rider's logged rides (docs/PLAN.md, Ride detection). The ride service
/// hands finished rides to the app, which keeps them here first, marked
/// pending until [RidesSync] has sent them.
class RidesRepository {
  RidesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final HopinDatabase _db;
  final DateTime Function() _clock;
  var _lastStamp = 0;

  /// Called after every local change (the sync uploads pending rows).
  void Function()? onChange;

  /// Newest first, without the removed.
  Stream<List<RideRecord>> watch() =>
      (_db.select(_db.rides)
            ..where((r) => r.deletedAt.isNull())
            ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
          .watch()
          .map((rows) => [for (final row in rows) rideFromRow(row)]);

  Future<void> save(RideRecord ride) async {
    final now = _stamp();
    final json = ride.toJson();
    await _db
        .into(_db.rides)
        .insertOnConflictUpdate(
          RidesCompanion.insert(
            id: ride.id,
            startedAt: ride.startedAt.microsecondsSinceEpoch,
            endedAt: ride.endedAt.microsecondsSinceEpoch,
            verdict: ride.verdict.code,
            distanceM: ride.distanceM,
            path: Value(json['path'] as String?),
            halts: Value(json['halts'] as String?),
            features: jsonEncode(ride.features),
            guideTo: Value(ride.guideTo),
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
    onChange?.call();
  }

  /// The rider's label; a ride that was not a bus loses its path.
  Future<void> setVerdict(String id, RideVerdict verdict) async {
    final row = await (_db.select(
      _db.rides,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (row == null) return;
    await save(rideFromRow(row).withVerdict(verdict));
  }

  Future<void> remove(String id) async {
    final now = _stamp();
    await (_db.update(_db.rides)..where((r) => r.id.equals(id))).write(
      RidesCompanion(
        deletedAt: Value(now),
        updatedAt: Value(now),
        pendingSince: Value(now),
      ),
    );
    onChange?.call();
  }

  /// Always later than the change before (see PlacesRepository).
  int _stamp() {
    final now = _clock().microsecondsSinceEpoch;
    return _lastStamp = now > _lastStamp ? now : _lastStamp + 1;
  }
}

RideRecord rideFromRow(RideRow row) =>
    RideRecord.fromJson({
      'id': row.id,
      'startedAt': row.startedAt,
      'endedAt': row.endedAt,
      'verdict': row.verdict,
      'distanceM': row.distanceM,
      'path': row.path,
      'halts': row.halts,
      'features': _features(row.features),
      'guideTo': row.guideTo,
    }) ??
    RideRecord(
      id: row.id,
      startedAt: DateTime.fromMicrosecondsSinceEpoch(row.startedAt),
      endedAt: DateTime.fromMicrosecondsSinceEpoch(row.endedAt),
      verdict: RideVerdict.of(row.verdict),
      distanceM: row.distanceM,
    );

Object? _features(String json) {
  try {
    return jsonDecode(json);
  } on FormatException {
    return null;
  }
}

/// Keeps the rides in step with `people/{uid}/rides`, like the places.
class RidesSync {
  RidesSync(this._db, this._remote, this._uid);

  static const _cursorKey = 'cursor.rides';
  static const _margin = 60 * 1000 * 1000;

  final HopinDatabase _db;
  final Remote _remote;
  final String _uid;
  StreamSubscription<List<RemoteDoc>>? _subscription;
  Future<void>? _running;
  bool _pushAgain = false;

  /// Told about uploads that failed; the rows stay pending.
  void Function(Object error, StackTrace stack)? onError;

  String get _collection => 'people/$_uid/rides';

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
      final pending = await (_db.select(
        _db.rides,
      )..where((r) => r.pendingSince.isNotNull())).get();
      for (final row in pending) {
        try {
          await _remote.put('$_collection/${row.id}', {
            'startedAt': DateTime.fromMicrosecondsSinceEpoch(row.startedAt),
            'endedAt': DateTime.fromMicrosecondsSinceEpoch(row.endedAt),
            'verdict': row.verdict,
            'distanceM': row.distanceM,
            'path': row.path,
            'halts': row.halts,
            'features': _features(row.features) ?? const <String, Object?>{},
            'fromName': row.fromName,
            'toName': row.toName,
            'guideTo': row.guideTo,
          }, deleted: row.deletedAt != null);
        } on Object catch (error, stack) {
          onError?.call(error, stack);
          return;
        }
        await (_db.update(_db.rides)..where(
              (r) =>
                  r.id.equals(row.id) &
                  r.pendingSince.equals(row.pendingSince!),
            ))
            .write(const RidesCompanion(pendingSince: Value(null)));
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
          _db.rides,
        )..where((r) => r.id.equals(doc.id))).getSingleOrNull();
        if (local?.pendingSince != null) continue;
        final d = doc.data;
        final started = d['startedAt'];
        final ended = d['endedAt'];
        if (started is! int || ended is! int) continue;
        await _db
            .into(_db.rides)
            .insertOnConflictUpdate(
              RidesCompanion.insert(
                id: doc.id,
                startedAt: started,
                endedAt: ended,
                verdict: d['verdict'] as String? ?? 'unknown',
                distanceM: (d['distanceM'] as num?)?.round() ?? 0,
                path: Value(d['path'] as String?),
                halts: Value(d['halts'] as String?),
                features: jsonEncode(d['features'] ?? const {}),
                guideTo: Value(d['guideTo'] as String?),
                fromName: Value(d['fromName'] as String?),
                toName: Value(d['toName'] as String?),
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
