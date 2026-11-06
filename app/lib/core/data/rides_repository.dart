import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/ride/stops.dart';

/// The rider's logged rides (docs/PLAN.md, Ride detection). The ride service
/// hands finished rides to the app, which keeps them here first, marked
/// pending until [RidesSync] has sent them. A bus ride's halts also go into
/// the pool both riders share, for the stops (Sharing and stops), and a
/// tagged bus ride's road into the ride roads, for the route it was (Which
/// bus), when the rider's [uid] is known.
class RidesRepository {
  RidesRepository(this._db, {this.uid, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final HopinDatabase _db;
  final String? uid;
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

  /// One ride as it changes; null once removed.
  Stream<RideRecord?> watchRide(String id) =>
      (_db.select(_db.rides)
            ..where((r) => r.id.equals(id) & r.deletedAt.isNull()))
          .watchSingleOrNull()
          .map((row) => row == null ? null : rideFromRow(row));

  /// Rides with a path and a name still missing, newest first.
  Future<List<RideRecord>> unnamed() async {
    final rows =
        await (_db.select(_db.rides)
              ..where(
                (r) =>
                    r.deletedAt.isNull() &
                    r.path.isNotNull() &
                    (r.fromName.isNull() | r.toName.isNull()),
              )
              ..orderBy([(r) => OrderingTerm.desc(r.startedAt)]))
            .get();
    return [for (final row in rows) rideFromRow(row)];
  }

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
            fromName: Value(ride.fromName),
            toName: Value(ride.toName),
            route: Value(_tagText(ride.route)),
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
    final bus = ride.verdict == RideVerdict.bus;
    await _pool(ride.id, bus ? ride.halts : const []);
    await _shareRoad(
      ride.id,
      bus && ride.path.length >= 2 ? ride.route : null,
      ride.path,
    );
    onChange?.call();
  }

  /// Shares a tagged bus ride's road with the route it was, or takes the
  /// ride's back (no [tag]); unchanged, nothing is written.
  Future<void> _shareRoad(
    String rideId,
    RouteTag? tag,
    List<GeoPoint> path,
  ) async {
    final uid = this.uid;
    if (uid == null) return;
    final row = await (_db.select(
      _db.routeRoads,
    )..where((r) => r.rideId.equals(rideId))).getSingleOrNull();
    if (tag == null) {
      if (row == null || row.deletedAt != null) return;
      final now = _stamp();
      await (_db.update(
        _db.routeRoads,
      )..where((r) => r.rideId.equals(rideId))).write(
        RouteRoadsCompanion(
          road: const Value(''),
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSince: Value(now),
        ),
      );
      return;
    }
    final road = encodePolyline(path);
    if (row != null &&
        row.deletedAt == null &&
        row.road == road &&
        row.route == tag.route &&
        row.direction == tag.direction &&
        row.number == tag.number) {
      return;
    }
    final now = _stamp();
    await _db
        .into(_db.routeRoads)
        .insertOnConflictUpdate(
          RouteRoadsCompanion.insert(
            rideId: rideId,
            uid: uid,
            route: tag.route,
            direction: tag.direction,
            number: tag.number,
            road: road,
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
  }

  /// The bus a ride was, from its page: tagging a ride Hopin was unsure of
  /// says it was a bus.
  Future<void> setRoute(String id, RouteTag? tag) async {
    final ride = await _ride(id);
    if (ride == null || ride.path.isEmpty) return;
    var tagged = ride.withRoute(tag);
    if (tag != null && ride.verdict == RideVerdict.unknown) {
      tagged = tagged.withVerdict(RideVerdict.bus);
    }
    if (tagged == ride) return;
    await save(tagged);
  }

  /// Puts a bus ride's bus-like halts in the pool, or takes the ride's back
  /// out; unchanged, nothing is written.
  Future<void> _pool(String rideId, List<Halt> halts) async {
    final uid = this.uid;
    if (uid == null) return;
    final points = encodeHalts(
      halts.where(
        (h) =>
            h.seconds >= StopFinder.shortestHalt &&
            h.seconds <= StopFinder.longestHalt,
      ),
    );
    final row = await (_db.select(
      _db.pooledHalts,
    )..where((r) => r.rideId.equals(rideId))).getSingleOrNull();
    if (points.isEmpty) {
      if (row == null || row.deletedAt != null) return;
      final now = _stamp();
      await (_db.update(
        _db.pooledHalts,
      )..where((r) => r.rideId.equals(rideId))).write(
        PooledHaltsCompanion(
          points: const Value(''),
          deletedAt: Value(now),
          updatedAt: Value(now),
          pendingSince: Value(now),
        ),
      );
      return;
    }
    if (row != null && row.deletedAt == null && row.points == points) return;
    final now = _stamp();
    await _db
        .into(_db.pooledHalts)
        .insertOnConflictUpdate(
          PooledHaltsCompanion.insert(
            rideId: rideId,
            uid: uid,
            points: points,
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
  }

  /// The rider's label; a ride that was not a bus loses its path and names.
  Future<void> setVerdict(String id, RideVerdict verdict) async {
    final ride = await _ride(id);
    if (ride == null || ride.verdict == verdict) return;
    await save(ride.withVerdict(verdict));
  }

  /// Names found for a ride's ends; a null keeps what it had.
  Future<void> setNames(String id, {String? from, String? to}) async {
    final ride = await _ride(id);
    if (ride == null || ride.path.isEmpty) return;
    final named = ride.withNames(from: from, to: to);
    if (named == ride) return;
    await save(named);
  }

  Future<RideRecord?> _ride(String id) async {
    final row = await (_db.select(
      _db.rides,
    )..where((r) => r.id.equals(id) & r.deletedAt.isNull())).getSingleOrNull();
    return row == null ? null : rideFromRow(row);
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
    await _pool(id, const []);
    await _shareRoad(id, null, const []);
    onChange?.call();
  }

  /// Always later than the change before (see PlacesRepository).
  int _stamp() {
    final now = _clock().microsecondsSinceEpoch;
    return _lastStamp = now > _lastStamp ? now : _lastStamp + 1;
  }
}

String? _tagText(RouteTag? tag) =>
    tag == null ? null : jsonEncode(tag.toJson());

Object? _tagJson(String? text) {
  if (text == null) return null;
  try {
    return jsonDecode(text);
  } on FormatException {
    return null;
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
      'fromName': row.fromName,
      'toName': row.toName,
      'route': _tagJson(row.route),
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
            'route': _tagJson(row.route),
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
                route: Value(_tagText(RouteTag.fromJson(d['route']))),
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
