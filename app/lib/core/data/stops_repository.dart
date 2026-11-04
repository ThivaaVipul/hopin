import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/stops.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/core/search/overpass.dart';

/// The bus stops (docs/PLAN.md, Sharing and stops): OpenStreetMap's, fetched
/// by square, and the ones learned from the riders' pooled halts, with the
/// riders' renames and removals. Worked out on the phone from the local
/// database, so they show offline.
class StopsRepository {
  StopsRepository(this._db, {required this.uid, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// A square of OSM's stops is fetched again after this long.
  static const refreshAfter = Duration(days: 30);

  static const _finder = StopFinder();

  final HopinDatabase _db;
  final String uid;
  final DateTime Function() _clock;
  final _random = Random();
  var _lastStamp = 0;

  /// Squares still to fetch, one fetch at a time.
  final _queue = <StopTile>{};
  Future<void>? _fetching;

  /// Called after a rename or removal (the sync sends it).
  void Function()? onChange;

  /// Every stop, again whenever the pool, OSM's stops or the notes change.
  /// (A watched query over the four tables: cancelling it is immediate,
  /// where an async generator waiting on table updates hangs until the next
  /// change.)
  Stream<List<Stop>> watch() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {
          _db.pooledHalts,
          _db.osmStops,
          _db.stopNotes,
          _db.stopNames,
        },
      )
      .watch()
      .asyncMap((_) => _all());

  Future<List<Stop>> _all() async {
    final pool = await (_db.select(
      _db.pooledHalts,
    )..where((r) => r.deletedAt.isNull())).get();
    final osm = await _db.select(_db.osmStops).get();
    final notes = await _db.select(_db.stopNotes).get();
    final names = await _db.select(_db.stopNames).get();
    final stops = _finder.find(
      rides: [
        for (final row in pool) RideHalts(row.rideId, _halts(row.points)),
      ],
      osm: [
        for (final row in osm)
          OsmStop(
            id: row.id,
            point: GeoPoint(row.lat, row.lng),
            names: PlaceNames(en: row.en, ta: row.ta, si: row.si),
          ),
      ],
      notes: [
        for (final row in notes)
          StopNote(
            id: row.id,
            point: GeoPoint(row.lat, row.lng),
            at: DateTime.fromMicrosecondsSinceEpoch(row.updatedAt),
            name: row.name,
            removed: row.removed,
          ),
      ],
    );
    return [
      for (final stop in stops)
        if (stop.learned && stop.names.isEmpty)
          switch (_nameNear(names, stop.point)) {
            final name? => stop.withNames(PlaceNames(en: name)),
            null => stop,
          }
        else
          stop,
    ];
  }

  static List<Halt> _halts(String points) {
    if (points.isEmpty) return const [];
    try {
      return decodeHalts(points);
    } on FormatException {
      return const [];
    }
  }

  static String? _nameNear(List<StopNameRow> names, GeoPoint point) => names
      .where((n) => GeoPoint(n.lat, n.lng).distanceTo(point) <= StopFinder.near)
      .firstOrNull
      ?.name;

  /// A learned stop's name, looked up once at street level and kept on this
  /// phone; null offline or where the map has none.
  Future<String?> nameOf(
    Stop stop,
    Nominatim nominatim, {
    required String language,
  }) async {
    final known = stop.names.inLanguage(language);
    if (known != null) return known;
    final cached = _nameNear(await _db.select(_db.stopNames).get(), stop.point);
    if (cached != null) return cached;
    final Destination? found;
    try {
      found = await nominatim.reverse(stop.point, zoom: 17);
    } on Exception {
      return null;
    }
    final name = found?.names.inLanguage(language) ?? found?.area;
    if (name == null || name.trim().isEmpty) return null;
    await _db
        .into(_db.stopNames)
        .insert(
          StopNamesCompanion.insert(
            lat: stop.point.lat,
            lng: stop.point.lng,
            name: name.trim(),
          ),
        );
    return name.trim();
  }

  /// Renames a learned stop for both riders.
  Future<void> rename(Stop stop, String name) => _note(stop, name: name);

  /// Removes a learned stop for both riders, for good.
  Future<void> remove(Stop stop) => _note(stop, removed: true);

  Future<void> _note(Stop stop, {String? name, bool removed = false}) async {
    final now = _stamp();
    await _db
        .into(_db.stopNotes)
        .insert(
          StopNotesCompanion.insert(
            id: _newId(),
            lat: stop.point.lat,
            lng: stop.point.lng,
            name: Value(name?.trim()),
            removed: Value(removed),
            by: uid,
            updatedAt: now,
            pendingSince: Value(now),
          ),
        );
    onChange?.call();
  }

  /// Fetches OSM's stops in the squares around [points] that are missing or
  /// a month old; offline, they wait for the next time.
  Future<void> ensureAround(Iterable<GeoPoint> points, Overpass overpass) {
    _queue.addAll(points.map(StopTile.at));
    return _fetching ??= _fetchQueued(
      overpass,
    ).whenComplete(() => _fetching = null);
  }

  Future<void> _fetchQueued(Overpass overpass) async {
    while (_queue.isNotEmpty) {
      final tile = _queue.first;
      _queue.remove(tile);
      final row = await (_db.select(
        _db.stopTiles,
      )..where((t) => t.key.equals(tile.key))).getSingleOrNull();
      final now = _clock();
      if (row != null &&
          now.difference(DateTime.fromMicrosecondsSinceEpoch(row.fetchedAt)) <
              refreshAfter) {
        continue;
      }
      final List<OsmStop> stops;
      try {
        stops = await overpass.stops(tile);
      } on Exception {
        _queue.clear();
        return;
      }
      await _db.transaction(() async {
        await (_db.delete(
          _db.osmStops,
        )..where((s) => s.tile.equals(tile.key))).go();
        for (final stop in stops) {
          await _db
              .into(_db.osmStops)
              .insertOnConflictUpdate(
                OsmStopsCompanion.insert(
                  id: Value(stop.id),
                  lat: stop.point.lat,
                  lng: stop.point.lng,
                  en: Value(stop.names.en),
                  ta: Value(stop.names.ta),
                  si: Value(stop.names.si),
                  tile: tile.key,
                ),
              );
        }
        await _db
            .into(_db.stopTiles)
            .insertOnConflictUpdate(
              StopTilesCompanion.insert(
                key: tile.key,
                fetchedAt: now.microsecondsSinceEpoch,
              ),
            );
      });
    }
  }

  int _stamp() {
    final now = _clock().microsecondsSinceEpoch;
    return _lastStamp = now > _lastStamp ? now : _lastStamp + 1;
  }

  String _newId() {
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
