import 'dart:async';

import 'package:drift/drift.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/route_files.dart';

/// The bus routes (docs/PLAN.md, Which bus): the route files the weekly job
/// publishes, kept on the phone as they came, so the buses show offline.
class RoutesRepository {
  RoutesRepository(this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// A file is asked for again after this long (the job runs weekly).
  static const checkEvery = Duration(days: 7);

  /// A file the release didn't have is asked for again after this long.
  static const missingEvery = Duration(days: 1);

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

  /// Fetches the files that are missing or a week old; offline, they wait
  /// for the next time. One refresh at a time.
  Future<void> refresh(RouteFiles files) =>
      _refreshing ??= _refresh(files).whenComplete(() => _refreshing = null);

  Future<void> _refresh(RouteFiles files) async {
    for (final source in RouteSource.values) {
      final row = await (_db.select(
        _db.routeData,
      )..where((r) => r.source.equals(source.name))).getSingleOrNull();
      final now = _clock();
      // A row with no body stands for a file the release didn't have.
      final wait = row == null || row.body.isEmpty ? missingEvery : checkEvery;
      if (row != null &&
          now.difference(DateTime.fromMicrosecondsSinceEpoch(row.checkedAt)) <
              wait) {
        continue;
      }
      final RouteFileAnswer answer;
      try {
        answer = await files.fetch(source, etag: row?.etag);
      } on Exception {
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
  }
}
