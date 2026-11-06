import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/data/routes_repository.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';

class RideState extends Equatable {
  const RideState({this.ride, this.loaded = false});

  /// Null once deleted.
  final RideRecord? ride;
  final bool loaded;

  bool get gone => loaded && ride == null;

  @override
  List<Object?> get props => [ride, loaded];
}

/// One ride's page: its path, its label, the bus it was, and Delete.
class RideCubit extends Cubit<RideState> {
  RideCubit(this._rides, this.id, {this._routes}) : super(const RideState());

  final RidesRepository _rides;
  final RoutesRepository? _routes;
  final String id;
  StreamSubscription<RideRecord?>? _ride;

  void start() {
    _ride = _rides.watchRide(id).listen((ride) {
      if (!isClosed) emit(RideState(ride: ride, loaded: true));
    });
  }

  /// Bus, Not a bus or Unsure; Not a bus also removes the path and names.
  Future<void> label(RideVerdict verdict) => _rides.setVerdict(id, verdict);

  Future<void> delete() => _rides.remove(id);

  /// Every route direction Hopin knows, for "Which bus?".
  Future<List<RouteDirection>> directions() async =>
      await _routes?.watch().first ?? const [];

  /// The bus the ride was, or none; tagging an unsure ride says it was a
  /// bus, and its road joins the route's for both riders.
  Future<void> setRoute(RouteTag? tag) => _rides.setRoute(id, tag);

  @override
  Future<void> close() async {
    await _ride?.cancel();
    return super.close();
  }
}
