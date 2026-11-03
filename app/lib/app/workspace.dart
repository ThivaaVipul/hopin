import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/session/session_cubit.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/places_repository.dart';
import 'package:hopin/core/data/places_sync.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/data/remote/remote.dart';

typedef DatabaseOpener = HopinDatabase Function(String uid);

/// One signed-in person's data: their database, repositories and sync. The
/// sync runs only while the account is a rider (the rules let nothing else in).
class Workspace {
  Workspace(this.uid, HopinDatabase db, Remote remote)
    : _db = db,
      places = PlacesRepository(db),
      recents = RecentsRepository(db),
      settings = SettingsStore(db),
      _sync = PlacesSync(db, remote, uid) {
    places.onChange = () => unawaited(_sync.push());
  }

  final String uid;
  final HopinDatabase _db;
  final PlacesRepository places;
  final RecentsRepository recents;
  final SettingsStore settings;
  final PlacesSync _sync;

  Future<void> setRider({required bool isRider}) =>
      isRider ? _sync.start() : _sync.stop();

  Future<void> close() async {
    await _sync.stop();
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
