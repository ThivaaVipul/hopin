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
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get pendingSince => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// This phone's own choices and bookkeeping (sync cursors, one-time cards).
@DataClassName('SettingRow')
class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// One database per account on a phone (`hopin_<uid>`).
@DriftDatabase(tables: [Places, Recents, Rides, Settings])
class HopinDatabase extends _$HopinDatabase {
  HopinDatabase(super.executor);

  factory HopinDatabase.forAccount(String uid) =>
      HopinDatabase(driftDatabase(name: 'hopin_$uid'));

  @override
  int get schemaVersion => 3;

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
