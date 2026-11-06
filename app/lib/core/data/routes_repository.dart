import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/route_files.dart';
import 'package:hopin/core/update/updates.dart' show installedBuild;

/// The bus routes (docs/PLAN.md, Which bus): the route files the weekly job
/// publishes, kept on the phone as they came, so the buses show offline,
/// with the riders' shared notes on them (board lines, removals), and the
/// routes the riders added by hand.
class RoutesRepository {
  RoutesRepository(
    this._db, {
    required this.uid,
    DateTime Function()? clock,
    this.build = installedBuild,
  }) : _clock = clock ?? DateTime.now;

  /// A file is asked for again after this long. Asking costs next to
  /// nothing when it hasn't changed (a 304 with no body), so a new week's
  /// files, or a rebuilt one, reach the phone within a day.
  static const checkEvery = Duration(days: 1);

  /// This app's build: after an update every file is asked for at once, so
  /// a fix that needs new route data has it straight away.
  final int build;

  /// The build that last asked for the files, in the settings table.
  static const _askedBy = 'routes.build';

  final HopinDatabase _db;
  final String uid;
  final DateTime Function() _clock;
  final _random = Random();
  var _lastStamp = 0;
  Future<void>? _refreshing;

  /// A road goes up as an encoded polyline of at most this many letters
  /// (the rules' limit); a longer one is thinned until it fits.
  static const roadLetters = 20000;

  /// Called after a note or a hand route changes (the syncs send it).
  void Function()? onChange;

  /// The route directions the buses are found among: the riders' board
  /// lines on them, the removed ones left out.
  Stream<List<RouteDirection>> watch() => watchNoted().map(
    (all) => [
      for (final noted in all)
        if (!noted.removed) noted.direction,
    ],
  );

  /// Every route direction on the phone with the newest note on it, again
  /// whenever a file, a note or a hand route changes: the route files' (a
  /// file this app can't read is left out), then the hand routes' both
  /// ways. (Its query is its own: drift shares watched queries by their SQL
  /// alone, so a second "SELECT 1" beside the stops' would follow the stops'
  /// tables instead.)
  Stream<List<NotedDirection>> watchNoted() => _db
      .customSelect(
        'SELECT body FROM route_data',
        readsFrom: {
          _db.routeData,
          _db.routeNotes,
          _db.handRoutes,
          _db.routeRoads,
        },
      )
      .watch()
      .asyncMap((rows) async {
        final notes = await _db.select(_db.routeNotes).get();
        final hand = await (_db.select(
          _db.handRoutes,
        )..where((r) => r.deletedAt.isNull())).get();
        final directions = [
          for (final row in rows) ...?_parse(row.read<String>('body')),
          for (final row in hand) ..._handRoute(row).directions,
        ];
        return withNotes(
          [...directions, ...await _ridden(directions)],
          [
            for (final note in notes)
              RouteNote(
                route: note.route,
                direction: note.direction,
                at: DateTime.fromMicrosecondsSinceEpoch(note.updatedAt),
                board: PlaceNames(en: note.en, ta: note.ta, si: note.si),
                removed: note.removed,
              ),
          ],
        );
      });

  /// Gives a direction board lines of the riders' own, for both riders: a
  /// line left empty, or the same as the file's, keeps the file's.
  Future<void> setBoard(NotedDirection noted, PlaceNames lines) {
    final file = noted.file.board;
    String? own(String? line, String? fileLine) {
      final text = line?.trim() ?? '';
      return text.isEmpty || text == fileLine ? null : text;
    }

    return _note(
      noted.file,
      PlaceNames(
        en: own(lines.en, file.en),
        ta: own(lines.ta, file.ta),
        si: own(lines.si, file.si),
      ),
      removed: noted.removed,
    );
  }

  /// Removes directions for both riders, or puts them back; their board
  /// lines stay as they are.
  Future<void> setRemoved(
    Iterable<NotedDirection> directions, {
    required bool removed,
  }) async {
    for (final noted in directions) {
      await _note(
        noted.file,
        noted.note?.board ?? const PlaceNames(),
        removed: removed,
        tell: false,
      );
    }
    onChange?.call();
  }

  Future<void> _note(
    RouteDirection file,
    PlaceNames board, {
    required bool removed,
    bool tell = true,
  }) async {
    final now = _stamp();
    await _db
        .into(_db.routeNotes)
        .insert(
          RouteNotesCompanion.insert(
            id: _newId(),
            route: file.routeId,
            direction: file.noteKey,
            ta: Value(board.ta),
            si: Value(board.si),
            en: Value(board.en),
            removed: Value(removed),
            by: uid,
            updatedAt: now,
            pendingSince: Value(now),
          ),
        );
    if (tell) onChange?.call();
  }

  /// A hand route by its directions' [routeId], again whenever it changes;
  /// null for none, or a deleted one.
  Stream<HandRoute?> watchHand(String routeId) {
    final id = HandRoute.idIn(routeId);
    if (id == null) return Stream.value(null);
    return (_db.select(
      _db.handRoutes,
    )..where((r) => r.id.equals(id))).watchSingleOrNull().map(
      (row) => row == null || row.deletedAt != null ? null : _handRoute(row),
    );
  }

  /// Adds a route by hand, or changes one (by its [HandRoute.id]), for both
  /// riders. A new one's id is made here; returns the route as kept.
  Future<HandRoute> saveHand(HandRoute route) async {
    final kept = HandRoute(
      id: route.id.isEmpty ? _newId() : route.id,
      number: route.number.trim(),
      from: route.from,
      to: route.to,
      via: route.via,
      road: route.road,
    );
    final now = _stamp();
    await _db
        .into(_db.handRoutes)
        .insertOnConflictUpdate(
          HandRoutesCompanion.insert(
            id: kept.id,
            number: kept.number,
            fromLat: kept.from.point.lat,
            fromLng: kept.from.point.lng,
            fromEn: Value(_line(kept.from.names.en)),
            fromTa: Value(_line(kept.from.names.ta)),
            fromSi: Value(_line(kept.from.names.si)),
            toLat: kept.to.point.lat,
            toLng: kept.to.point.lng,
            toEn: Value(_line(kept.to.names.en)),
            toTa: Value(_line(kept.to.names.ta)),
            toSi: Value(_line(kept.to.names.si)),
            via: _viaText(kept.via),
            road: _roadText(kept.road),
            by: uid,
            updatedAt: now,
            deletedAt: const Value(null),
            pendingSince: Value(now),
          ),
        );
    onChange?.call();
    return kept;
  }

  /// Deletes a route added by hand, for both riders.
  Future<void> deleteHand(String id) async {
    final now = _stamp();
    await (_db.update(_db.handRoutes)..where((r) => r.id.equals(id))).write(
      HandRoutesCompanion(
        by: Value(uid),
        updatedAt: Value(now),
        deletedAt: Value(now),
        pendingSince: Value(now),
      ),
    );
    onChange?.call();
  }

  /// The tagged rides' roads, each as the direction it was tagged with
  /// along where the bus went; a road whose direction the phone no longer
  /// has is left out.
  Future<List<RouteDirection>> _ridden(List<RouteDirection> directions) async {
    final roads = await (_db.select(
      _db.routeRoads,
    )..where((r) => r.deletedAt.isNull())).get();
    if (roads.isEmpty) return const [];
    final byKey = {for (final d in directions) (d.routeId, d.noteKey): d};
    return [
      for (final road in roads)
        if (byKey[(road.route, road.direction)] case final direction?)
          if (_road(road.road) case final points when points.length >= 2)
            direction.alongRide(points),
    ];
  }

  static HandRoute _handRoute(HandRouteRow row) => HandRoute(
    id: row.id,
    number: row.number,
    from: RouteTown(
      GeoPoint(row.fromLat, row.fromLng),
      PlaceNames(en: row.fromEn, ta: row.fromTa, si: row.fromSi),
    ),
    to: RouteTown(
      GeoPoint(row.toLat, row.toLng),
      PlaceNames(en: row.toEn, ta: row.toTa, si: row.toSi),
    ),
    via: _via(row.via),
    road: _road(row.road),
  );

  static List<RouteTown> _via(String text) {
    try {
      return [
        for (final town
            in (jsonDecode(text) as List).whereType<Map<String, Object?>>())
          if (town case {'lat': final num lat, 'lng': final num lng})
            RouteTown(
              GeoPoint(lat.toDouble(), lng.toDouble()),
              PlaceNames(
                en: town['en'] as String?,
                ta: town['ta'] as String?,
                si: town['si'] as String?,
              ),
            ),
      ];
    } on Object {
      return const [];
    }
  }

  static String _viaText(List<RouteTown> via) => jsonEncode([
    for (final town in via)
      {
        'lat': double.parse(town.point.lat.toStringAsFixed(6)),
        'lng': double.parse(town.point.lng.toStringAsFixed(6)),
        'en': ?_line(town.names.en),
        'ta': ?_line(town.names.ta),
        'si': ?_line(town.names.si),
      },
  ]);

  static List<GeoPoint> _road(String text) {
    if (text.isEmpty) return const [];
    try {
      return decodePolyline(text);
    } on Object {
      return const [];
    }
  }

  /// The road as an encoded polyline the rules take, thinned harder until
  /// it fits.
  static String _roadText(List<GeoPoint> road) {
    var text = encodePolyline(road);
    for (var tolerance = 20.0; text.length > roadLetters; tolerance *= 2) {
      text = encodePolyline(thinLine(road, toleranceM: tolerance));
    }
    return text;
  }

  /// A name as the rules take it: trimmed, at most 120 letters, or none.
  static String? _line(String? name) {
    final text = name?.trim() ?? '';
    if (text.isEmpty) return null;
    return text.length > 120 ? text.substring(0, 120) : text;
  }

  /// Every change gets a later stamp than the one before.
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

  static List<RouteDirection>? _parse(String body) {
    try {
      return parseRouteFile(body);
    } on FormatException {
      return null;
    }
  }

  /// Fetches the files that are missing or a day old, or all of them after
  /// an app update; offline, they wait for the next time. One refresh at a
  /// time.
  Future<void> refresh(RouteFiles files) =>
      _refreshing ??= _refresh(files).whenComplete(() => _refreshing = null);

  Future<void> _refresh(RouteFiles files) async {
    final askedBy = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_askedBy))).getSingleOrNull();
    final updated = askedBy?.value != '$build';
    for (final source in RouteSource.files) {
      // A row with no body stands for a file the release didn't have.
      final row = await (_db.select(
        _db.routeData,
      )..where((r) => r.source.equals(source.name))).getSingleOrNull();
      final now = _clock();
      if (!updated &&
          row != null &&
          now.difference(DateTime.fromMicrosecondsSinceEpoch(row.checkedAt)) <
              checkEvery) {
        continue;
      }
      final RouteFileAnswer answer;
      try {
        answer = await files.fetch(source, etag: row?.etag);
      } on Exception {
        // Offline: the files, and an update's check, wait for next time.
        return;
      }
      final checked = now.microsecondsSinceEpoch;
      final body = answer.body;
      if (answer.status == 200 && body != null && _parse(body) != null) {
        await _db
            .into(_db.routeData)
            .insertOnConflictUpdate(
              RouteDataCompanion.insert(
                source: source.name,
                body: body,
                etag: Value(answer.etag),
                checkedAt: checked,
              ),
            );
      } else if (row != null) {
        // Unchanged (304), or missing, broken or of a newer format than this
        // app reads: what the phone has stays, and it waits.
        await _db
            .update(_db.routeData)
            .replace(row.copyWith(checkedAt: checked));
      } else {
        await _db
            .into(_db.routeData)
            .insert(
              RouteDataCompanion.insert(
                source: source.name,
                body: '',
                checkedAt: checked,
              ),
            );
      }
    }
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: _askedBy, value: '$build'),
        );
  }
}
