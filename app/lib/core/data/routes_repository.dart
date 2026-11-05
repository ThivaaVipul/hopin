import 'dart:async';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/route_files.dart';
import 'package:hopin/core/update/updates.dart' show installedBuild;

/// The bus routes (docs/PLAN.md, Which bus): the route files the weekly job
/// publishes, kept on the phone as they came, so the buses show offline.
class RoutesRepository {
  RoutesRepository(
    this._db, {
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
  final DateTime Function() _clock;
  Future<void>? _refreshing;

  /// Every route direction on the phone, again whenever a file changes. A
  /// file this app can't read is left out. (It watches its own table's rows:
  /// drift shares watched queries by their SQL alone, so a second
  /// "SELECT 1" beside the stops' would follow the stops' tables instead.)
  Stream<List<RouteDirection>> watch() => _db
      .select(_db.routeData)
      .watch()
      .map((rows) => [for (final row in rows) ...?_parse(row.body)]);

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
    for (final source in RouteSource.values) {
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
