import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/data/rides_repository.dart';
import 'package:hopin/core/ride/ride_record.dart';

class RideState extends Equatable {
  const RideState({this.ride, this.loaded = false});

  /// Null once deleted.
  final RideRecord? ride;
  final bool loaded;

  bool get gone => loaded && ride == null;

  @override
  List<Object?> get props => [ride, loaded];
}

/// One ride's page: its path, its label and Delete.
class RideCubit extends Cubit<RideState> {
  RideCubit(this._rides, this.id) : super(const RideState());

  final RidesRepository _rides;
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

  @override
  Future<void> close() async {
    await _ride?.cancel();
    return super.close();
  }
}
