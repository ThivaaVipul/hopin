import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/features/routes/cubit/routes_cubit.dart';

class RouteState extends Equatable {
  const RouteState({this.route, this.hand, this.loaded = false});

  /// Null once loaded: the route files no longer have it, or it was a hand
  /// route and was deleted.
  final KnownRoute? route;

  /// The route as added by hand, for one that was.
  final HandRoute? hand;
  final bool loaded;

  @override
  List<Object?> get props => [route, hand, loaded];
}

/// A route's page (docs/PLAN.md, Which bus): its road, its towns and each
/// direction's board, with the riders' board lines and Remove shared as
/// notes; a route added by hand is changed or deleted instead.
class RouteCubit extends Cubit<RouteState> {
  RouteCubit(this._routes, this.id) : super(const RouteState());

  final RoutesRepository _routes;
  final String id;
  StreamSubscription<List<NotedDirection>>? _watch;
  StreamSubscription<HandRoute?>? _watchHand;
  KnownRoute? _route;
  HandRoute? _hand;
  var _routeIn = false;

  void start() {
    _watch = _routes.watchNoted().listen((all) {
      final mine = [
        for (final noted in all)
          if (noted.file.routeId == id) noted,
      ];
      final directions = [
        for (final noted in mine)
          if (!noted.file.ridden) noted,
      ];
      _route = directions.isEmpty
          ? null
          : KnownRoute(
              directions,
              ridden: [
                for (final noted in mine)
                  if (noted.file.ridden) noted,
              ],
            );
      _routeIn = true;
      _show();
    });
    if (HandRoute.idIn(id) != null) {
      _watchHand = _routes.watchHand(id).listen((hand) {
        _hand = hand;
        _show();
      });
    }
  }

  void _show() {
    if (isClosed || !_routeIn) return;
    emit(RouteState(route: _route, hand: _hand, loaded: true));
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

  /// Deletes a route added by hand, for both riders.
  Future<void> delete() async {
    final hand = state.hand;
    if (hand != null) await _routes.deleteHand(hand.id);
  }

  @override
  Future<void> close() async {
    await _watch?.cancel();
    await _watchHand?.cancel();
    return super.close();
  }
}
