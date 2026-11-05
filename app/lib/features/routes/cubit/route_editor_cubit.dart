import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/search/osrm.dart';

class RouteEditorState extends Equatable {
  const RouteEditorState({
    this.id = '',
    this.number = '',
    this.from,
    this.to,
    this.via = const [],
    this.road,
    this.drawing = false,
    this.failed = false,
    this.saved = false,
    this.loaded = true,
  });

  /// The hand route being changed; empty for a new one.
  final String id;
  final String number;
  final RouteTown? from;
  final RouteTown? to;

  /// The towns on the way, in order.
  final List<RouteTown> via;

  /// The road through the towns as they are; null until it is drawn.
  final List<GeoPoint>? road;
  final bool drawing;

  /// The last try to draw the road failed (no network, or no road).
  final bool failed;
  final bool saved;

  /// False while a route being changed loads.
  final bool loaded;

  bool get editing => id.isNotEmpty;

  /// Every town in order: the start, those on the way, the end.
  List<RouteTown> get towns => [?from, ...via, ?to];

  bool get canSave =>
      number.trim().isNotEmpty &&
      from != null &&
      to != null &&
      road != null &&
      !drawing;

  @override
  List<Object?> get props => [
    id,
    number,
    from,
    to,
    via,
    road,
    drawing,
    failed,
    saved,
    loaded,
  ];
}

/// Adding a route by hand, or changing one (docs/PLAN.md, Which bus): its
/// number, its two end towns and the towns on the way, with the road drawn
/// by OSRM each time the towns change, shown before it is saved.
class RouteEditorCubit extends Cubit<RouteEditorState> {
  RouteEditorCubit(this._routes, this._osrm, {this.routeId})
    : super(RouteEditorState(loaded: routeId == null));

  /// At most this many towns on the way.
  static const maxVia = 5;

  final RoutesRepository _routes;
  final Osrm _osrm;

  /// The route to change, or null to add one.
  final String? routeId;
  var _draws = 0;

  Future<void> start() async {
    final routeId = this.routeId;
    if (routeId == null) return;
    final route = await _routes.watchHand(routeId).first;
    if (isClosed || route == null) return;
    emit(
      RouteEditorState(
        id: route.id,
        number: route.number,
        from: route.from,
        to: route.to,
        via: route.via,
        road: route.road.isEmpty ? null : route.road,
      ),
    );
  }

  /// The number as typed; a road being drawn goes on.
  void setNumber(String number) =>
      emit(_with(number: number, drawing: state.drawing, failed: state.failed));

  Future<void> setFrom(RouteTown town) => _draw(_with(from: town));

  Future<void> setTo(RouteTown town) => _draw(_with(to: town));

  Future<void> addTown(RouteTown town) => state.via.length >= maxVia
      ? Future.value()
      : _draw(_with(via: [...state.via, town]));

  Future<void> removeTown(int index) =>
      _draw(_with(via: [...state.via]..removeAt(index)));

  /// Draws the road again, after a try failed.
  Future<void> drawAgain() => _draw(state);

  Future<void> save() async {
    final state = this.state;
    if (!state.canSave) return;
    await _routes.saveHand(
      HandRoute(
        id: state.id,
        number: state.number,
        from: state.from!,
        to: state.to!,
        via: state.via,
        road: state.road!,
      ),
    );
    if (!isClosed) emit(_with(saved: true));
  }

  /// [next] with its road drawn afresh through its towns; an answer for
  /// towns changed since is dropped.
  Future<void> _draw(RouteEditorState next) async {
    final draw = ++_draws;
    if (next.from == null || next.to == null) {
      emit(_with(base: next, noRoad: true));
      return;
    }
    emit(_with(base: next, noRoad: true, drawing: true));
    final road = await _osrm.road([for (final town in next.towns) town.point]);
    if (isClosed || draw != _draws) return;
    emit(road == null ? _with(noRoad: true, failed: true) : _with(road: road));
  }

  /// The state with some fields changed; drawing and failed reset unless
  /// given.
  RouteEditorState _with({
    RouteEditorState? base,
    String? number,
    RouteTown? from,
    RouteTown? to,
    List<RouteTown>? via,
    List<GeoPoint>? road,
    bool noRoad = false,
    bool drawing = false,
    bool failed = false,
    bool? saved,
  }) {
    final s = base ?? state;
    return RouteEditorState(
      id: s.id,
      number: number ?? s.number,
      from: from ?? s.from,
      to: to ?? s.to,
      via: via ?? s.via,
      road: noRoad ? null : (road ?? s.road),
      drawing: drawing,
      failed: failed,
      saved: saved ?? s.saved,
      loaded: s.loaded,
    );
  }
}
