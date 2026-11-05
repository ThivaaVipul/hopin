import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/routes.dart';

/// One route from the route files: its directions, each with the riders'
/// newest note on it.
class KnownRoute extends Equatable {
  const KnownRoute(this.directions);

  /// Never empty; the list names the route by the first.
  final List<NotedDirection> directions;

  RouteDirection get first => directions.first.direction;
  String get id => first.routeId;
  String get number => first.number;

  /// Removed once every direction is.
  bool get removed => directions.every((d) => d.removed);

  /// Where the first direction starts, as the board back there reads (a
  /// rider's lines and all), so both ends read alike.
  PlaceNames get from {
    final origin = directions.first.file.origin;
    for (final noted in directions.skip(1)) {
      if (noted.file.board == origin) return noted.direction.board;
    }
    return first.origin;
  }

  @override
  List<Object?> get props => [directions];
}

/// [all]'s directions as routes, in number order ("2" before "15-87", and
/// numbers that start with letters last).
List<KnownRoute> groupRoutes(List<NotedDirection> all) {
  final byId = <String, List<NotedDirection>>{};
  for (final noted in all) {
    (byId[noted.file.routeId] ??= []).add(noted);
  }
  return [for (final directions in byId.values) KnownRoute(directions)]
    ..sort(_inNumberOrder);
}

int _inNumberOrder(KnownRoute a, KnownRoute b) {
  final lead = _lead(a.number).compareTo(_lead(b.number));
  if (lead != 0) return lead;
  final number = plainNumber(a.number).compareTo(plainNumber(b.number));
  return number != 0 ? number : a.id.compareTo(b.id);
}

final _digits = RegExp(r'^\d+');

int _lead(String number) =>
    int.tryParse(_digits.stringMatch(number.trim()) ?? '') ?? 1 << 30;

/// Whether [route] carries a number that starts with [query] (as on the bus,
/// so "15" finds "15-87"); an empty query finds every route.
bool carriesNumber(KnownRoute route, String query) {
  final wanted = plainNumber(query);
  if (wanted.isEmpty) return true;
  return [
    route.number,
    ...route.first.also,
  ].any((number) => plainNumber(number).startsWith(wanted));
}

class RoutesState extends Equatable {
  const RoutesState({
    this.routes = const [],
    this.query = '',
    this.loaded = false,
  });

  /// Every route, in number order.
  final List<KnownRoute> routes;
  final String query;
  final bool loaded;

  /// The routes the search finds.
  List<KnownRoute> get shown => [
    for (final route in routes)
      if (carriesNumber(route, query)) route,
  ];

  @override
  List<Object?> get props => [routes, query, loaded];
}

/// Settings > Routes (docs/PLAN.md, Which bus): every route on the phone,
/// searched by number.
class RoutesCubit extends Cubit<RoutesState> {
  RoutesCubit(this._routes) : super(const RoutesState());

  final RoutesRepository _routes;
  StreamSubscription<List<NotedDirection>>? _watch;

  void start() {
    _watch = _routes.watchNoted().listen((all) {
      if (isClosed) return;
      emit(
        RoutesState(routes: groupRoutes(all), query: state.query, loaded: true),
      );
    });
  }

  void search(String query) => emit(
    RoutesState(routes: state.routes, query: query, loaded: state.loaded),
  );

  @override
  Future<void> close() async {
    await _watch?.cancel();
    return super.close();
  }
}
