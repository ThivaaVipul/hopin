import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'database.g.dart';

/// Saved places: a copy of `people/{uid}/places`, plus this phone's writes
/// that the server hasn't confirmed yet ([pendingSince]).
@DataClassName('PlaceRow')
class Places extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get kind => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get placeEn => text().nullable()();
  TextColumn get placeTa => text().nullable()();
  TextColumn get placeSi => text().nullable()();

  /// The rider's own order (Settings, Places); 0 until they reorder.
  IntColumn get position => integer().withDefault(const Constant(0))();

  /// A guide here shares the ride by itself.
  BoolColumn get shareRides => boolean().withDefault(const Constant(false))();

  /// Microseconds since the epoch; the server's time once synced.
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The last few destinations, on this phone only.
@DataClassName('RecentRow')
class Recents extends Table {
  /// The position rounded to about 10 m, so the same place is kept once.
  TextColumn get key => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get placeEn => text().nullable()();
  TextColumn get placeTa => text().nullable()();
  TextColumn get placeSi => text().nullable()();
  TextColumn get area => text().nullable()();
  IntColumn get usedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Logged vehicle rides: a copy of `people/{uid}/rides`, plus this phone's
/// writes that the server hasn't confirmed yet ([pendingSince]).
@DataClassName('RideRow')
class Rides extends Table {
  TextColumn get id => text()();

  /// Microseconds since the epoch.
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer()();

  /// `bus`, `not_bus` or `unknown`.
  TextColumn get verdict => text()();
  IntColumn get distanceM => integer()();

  /// Encoded polylines; none for a ride that was not a bus.
  TextColumn get path => text().nullable()();
  TextColumn get halts => text().nullable()();

  /// The bus logic's numbers, as JSON.
  TextColumn get features => text()();
  TextColumn get guideTo => text().nullable()();
  TextColumn get fromName => text().nullable()();
  TextColumn get toName => text().nullable()();

  /// The bus it was, as tagged: RouteTag as JSON.
  TextColumn get route => text().nullable()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// This phone's own choices and bookkeeping (sync cursors, one-time cards).
/// A bus ride's halts in the pool both riders share (`halts/{rideId}`):
/// the stops are worked out from these (docs/PLAN.md, Sharing and stops).
@DataClassName('PooledHaltsRow')
class PooledHalts extends Table {
  TextColumn get rideId => text()();
  TextColumn get uid => text()();

  /// "lat,lng,seconds;..." (ride_record.dart); empty once taken back.
  TextColumn get points => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {rideId};
}

/// A rename or removal of a learned stop, shared (`stopNotes/{id}`).
@DataClassName('StopNoteRow')
class StopNotes extends Table {
  TextColumn get id => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get name => text().nullable()();
  BoolColumn get removed => boolean().withDefault(const Constant(false))();
  TextColumn get by => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// OpenStreetMap's bus stops, by square (Overpass), on this phone only.
@DataClassName('OsmStopRow')
class OsmStops extends Table {
  IntColumn get id => integer()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get en => text().nullable()();
  TextColumn get ta => text().nullable()();
  TextColumn get si => text().nullable()();
  TextColumn get tile => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// When each square of OSM's stops was fetched.
@DataClassName('StopTileRow')
class StopTiles extends Table {
  TextColumn get key => text()();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Learned stops' names, looked up once at street level, on this phone.
@DataClassName('StopNameRow')
class StopNames extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  TextColumn get name => text()();
}

/// The route files from the `data` release (docs/ARCHITECTURE.md, Route
/// data), one row per source, kept as they came.
@DataClassName('RouteDataRow')
class RouteData extends Table {
  /// `osm`, `ntc` or `lmt`.
  TextColumn get source => text()();
  TextColumn get body => text()();
  TextColumn get etag => text().nullable()();

  /// When the file was last asked for, in microseconds since the epoch.
  IntColumn get checkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {source};
}

/// The riders' changes to the route files' directions (`routeNotes/{id}`,
/// docs/PLAN.md, Which bus): board lines and removals, shared by both
/// riders; the newest note on a direction wins.
@DataClassName('RouteNoteRow')
class RouteNotes extends Table {
  TextColumn get id => text()();

  /// The route's id and the direction's key (RouteDirection.noteKey).
  TextColumn get route => text()();
  TextColumn get direction => text()();

  /// Board lines in place of the file's; null keeps the file's.
  TextColumn get ta => text().nullable()();
  TextColumn get si => text().nullable()();
  TextColumn get en => text().nullable()();
  BoolColumn get removed => boolean().withDefault(const Constant(false))();
  TextColumn get by => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The routes the riders added by hand (`routes/{id}`, docs/PLAN.md, Which
/// bus), shared by both riders; deleting one marks it.
@DataClassName('HandRouteRow')
class HandRoutes extends Table {
  TextColumn get id => text()();
  TextColumn get number => text()();
  RealColumn get fromLat => real()();
  RealColumn get fromLng => real()();
  TextColumn get fromEn => text().nullable()();
  TextColumn get fromTa => text().nullable()();
  TextColumn get fromSi => text().nullable()();
  RealColumn get toLat => real()();
  RealColumn get toLng => real()();
  TextColumn get toEn => text().nullable()();
  TextColumn get toTa => text().nullable()();
  TextColumn get toSi => text().nullable()();

  /// The towns on the way, in order, as JSON: [{"lat", "lng", "en", "ta",
  /// "si"}].
  TextColumn get via => text()();

  /// The road OSRM drew, as an encoded polyline.
  TextColumn get road => text()();
  TextColumn get by => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Tagged bus rides' roads (`routeRoads/{rideId}`, docs/PLAN.md, Which bus):
/// each one's bus part, pooled, so the route it was matches along it for
/// both riders.
@DataClassName('RouteRoadRow')
class RouteRoads extends Table {
  TextColumn get rideId => text()();
  TextColumn get uid => text()();

  /// The route's id and the direction's key (RouteTag).
  TextColumn get route => text()();
  TextColumn get direction => text()();
  TextColumn get number => text()();

  /// The ride's bus part, an encoded polyline; empty once taken back.
  TextColumn get road => text()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {rideId};
}

@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// One database per account on a phone (`hopin_<uid>`).
@DriftDatabase(
  tables: [
    Places,
    Recents,
    Rides,
    PooledHalts,
    StopNotes,
    OsmStops,
    StopTiles,
    StopNames,
    RouteData,
    RouteNotes,
    HandRoutes,
    RouteRoads,
    Settings,
  ],
)
class HopinDatabase extends _$HopinDatabase {
  HopinDatabase(super.executor);

  factory HopinDatabase.forAccount(String uid) =>
      HopinDatabase(driftDatabase(name: 'hopin_$uid'));

  @override
  int get schemaVersion => 9;

  // Places are a copy of Firestore, so a new schema rebuilds the tables and the
  // sync fills them again from the start; unsynced writes are read back from
  // Firestore's own queue. The settings table (a plain key and value) stays,
  // so this phone's choices survive, but its sync cursors go. No migrations by
  // hand (CLAUDE.md).
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      for (final table in allTables) {
        if (table == settings) continue;
        await migrator.deleteTable(table.actualTableName);
        await migrator.createTable(table);
      }
      await (delete(settings)..where((s) => s.key.like('cursor.%'))).go();
    },
  );
}
