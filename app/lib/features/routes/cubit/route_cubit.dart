import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';

class RouteState extends Equatable {
  const RouteState({this.route, this.loaded = false});

  /// Null once loaded: the route files no longer have it.
  final KnownRoute? route;
  final bool loaded;

  @override
  List<Object?> get props => [route, loaded];
}

/// A route's page (docs/PLAN.md, Which bus): its road, its towns and each
/// direction's board, with the riders' board lines and Remove shared as
/// notes.
class RouteCubit extends Cubit<RouteState> {
  RouteCubit(this._routes, this.id) : super(const RouteState());

  final RoutesRepository _routes;
  final String id;
  StreamSubscription<List<NotedDirection>>? _watch;

  void start() {
    _watch = _routes.watchNoted().listen((all) {
      if (isClosed) return;
      final directions = [
        for (final noted in all)
          if (noted.file.routeId == id) noted,
      ];
      emit(
        RouteState(
          route: directions.isEmpty ? null : KnownRoute(directions),
          loaded: true,
        ),
      );
    });
  }

  /// Board lines of the riders' own for one direction; an empty line keeps
  /// the file's.
  Future<void> setBoard(NotedDirection direction, PlaceNames lines) =>
      _routes.setBoard(direction, lines);

  /// Hides the route's buses for both riders, or shows them again.
  Future<void> setRemoved({required bool removed}) async {
    final route = state.route;
    if (route != null) {
      await _routes.setRemoved(route.directions, removed: removed);
    }
  }

  @override
  Future<void> close() async {
    await _watch?.cancel();
    return super.close();
  }
}
