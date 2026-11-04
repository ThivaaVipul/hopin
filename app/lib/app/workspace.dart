import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/core/data/app_settings.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/places_repository.dart';
import 'package:hopin/core/data/places_sync.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/data/ride_namer.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/data/settings_sync.dart';
import 'package:hopin/core/search/nominatim.dart';

typedef DatabaseOpener = HopinDatabase Function(String uid);

/// One signed-in person's data: their database, repositories and sync. The
/// sync runs only while the account is a rider (the rules let nothing else in).
class Workspace {
  Workspace(this.uid, HopinDatabase db, Remote remote)
    : _db = db,
      places = PlacesRepository(db),
      recents = RecentsRepository(db),
      settings = SettingsStore(db),
      rides = RidesRepository(db),
      _sync = PlacesSync(db, remote, uid),
      _ridesSync = RidesSync(db, remote, uid) {
    appSettings = AppSettings(settings);
    _settingsSync = SettingsSync(appSettings, settings, remote, uid);
    places.onChange = () => unawaited(_sync.push());
    appSettings.onChange = () => unawaited(_settingsSync.push());
    rides.onChange = () => unawaited(_ridesSync.push());
  }

  final String uid;
  final HopinDatabase _db;
  final PlacesRepository places;
  final RecentsRepository recents;
  final SettingsStore settings;

  /// The logged vehicle rides.
  final RidesRepository rides;

  /// The language and alert stages, which follow the account.
  late final AppSettings appSettings;
  final PlacesSync _sync;
  late final SettingsSync _settingsSync;
  final RidesSync _ridesSync;
  RideNamer? _namer;

  /// Names the rides' ends; one for the workspace, so Home and the Rides page
  /// never look the same ride up twice at once.
  RideNamer namer(Nominatim nominatim) => _namer ??= RideNamer(
    rides: rides,
    places: places,
    settings: appSettings,
    nominatim: nominatim,
  );

  Future<void> setRider({required bool isRider}) async {
    if (isRider) {
      await Future.wait([
        _sync.start(),
        _settingsSync.start(),
        _ridesSync.start(),
      ]);
    } else {
      await Future.wait([
        _sync.stop(),
        _settingsSync.stop(),
        _ridesSync.stop(),
      ]);
    }
  }

  Future<void> close() async {
    await Future.wait([_sync.stop(), _settingsSync.stop(), _ridesSync.stop()]);
    await _db.close();
  }
}

/// Opens the workspace when someone signs in and closes it when they leave,
/// for everything below it.
class WorkspaceScope extends StatefulWidget {
  const WorkspaceScope({
    super.key,
    required this.open,
    required this.remote,
    required this.child,
  });

  final DatabaseOpener open;
  final Remote remote;
  final Widget child;

  /// The signed-in person's workspace; null for the moment between signing
  /// out and leaving the screen.
  static Workspace? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_WorkspaceData>()?.workspace;

  @override
  State<WorkspaceScope> createState() => _WorkspaceScopeState();
}

class _WorkspaceScopeState extends State<WorkspaceScope> {
  Workspace? _workspace;

  void _follow(SessionState session) {
    final account = session.account;
    if (_workspace?.uid != account?.uid) {
      final old = _workspace;
      _workspace = account == null
          ? null
          : Workspace(account.uid, widget.open(account.uid), widget.remote);
      if (old != null) unawaited(old.close());
    }
    if (account != null) {
      unawaited(_workspace!.setRider(isRider: account.isRider));
    }
  }

  @override
  void initState() {
    super.initState();
    _follow(context.read<SessionCubit>().state);
  }

  @override
  void dispose() {
    unawaited(_workspace?.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<SessionCubit, SessionState>(
        listener: (context, session) => setState(() => _follow(session)),
        child: _WorkspaceData(workspace: _workspace, child: widget.child),
      );
}

class _WorkspaceData extends InheritedWidget {
  const _WorkspaceData({required this.workspace, required super.child});

  final Workspace? workspace;

  @override
  bool updateShouldNotify(_WorkspaceData old) => old.workspace != workspace;
}
