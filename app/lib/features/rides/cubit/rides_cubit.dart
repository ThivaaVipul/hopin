import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/nominatim.dart';

class RidesState extends Equatable {
  const RidesState({this.rides = const [], this.loaded = false});

  /// Newest first.
  final List<RideRecord> rides;
  final bool loaded;

  @override
  List<Object?> get props => [rides, loaded];
}

/// The Rides page (docs/PLAN.md, Rides page): every logged ride, from the
/// local database; opening it names the rides still unnamed.
class RidesCubit extends Cubit<RidesState> {
  RidesCubit(this._workspace, this._nominatim) : super(const RidesState());

  final Workspace _workspace;
  final Nominatim _nominatim;
  StreamSubscription<List<RideRecord>>? _rides;

  void start() {
    _rides = _workspace.rides.watch().listen((rides) {
      if (!isClosed) emit(RidesState(rides: rides, loaded: true));
    });
    unawaited(_workspace.namer(_nominatim).nameMissing());
  }

  @override
  Future<void> close() async {
    await _rides?.cancel();
    return super.close();
  }
}
