import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/search/nominatim.dart';

enum LocationStatus {
  checking,

  /// First time: the card explains why before Android asks.
  explain,
  denied,
  granted,
}

class HomeState extends Equatable {
  const HomeState({
    this.places = const [],
    this.location = LocationStatus.checking,
    this.me,
    this.destination,
    this.resolving = false,
  });

  final List<SavedPlace> places;
  final LocationStatus location;
  final GeoPoint? me;
  final Destination? destination;

  /// A dropped pin is being named after the nearest place.
  final bool resolving;

  HomeState copyWith({
    List<SavedPlace>? places,
    LocationStatus? location,
    GeoPoint? me,
    bool? resolving,
  }) => HomeState(
    places: places ?? this.places,
    location: location ?? this.location,
    me: me ?? this.me,
    destination: destination,
    resolving: resolving ?? this.resolving,
  );

  HomeState withDestination(
    Destination? destination, {
    bool resolving = false,
  }) => HomeState(
    places: places,
    location: location,
    me: me,
    destination: destination,
    resolving: resolving,
  );

  @override
  List<Object?> get props => [places, location, me, destination, resolving];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._workspace, this._location, this._nominatim)
    : super(const HomeState());

  final Workspace _workspace;
  final LocationService _location;
  final Nominatim _nominatim;
  StreamSubscription<List<SavedPlace>>? _places;
  StreamSubscription<GeoPoint>? _positions;

  Future<void> start() async {
    _places = _workspace.places.watch().listen(_onPlaces);
    final explained =
        await _workspace.settings.read(SettingsStore.locationExplained) != null;
    final access = await _location.check();
    if (isClosed) return;
    if (access == LocationAccess.granted) {
      await _track();
    } else {
      emit(
        state.copyWith(
          location: explained ? LocationStatus.denied : LocationStatus.explain,
        ),
      );
    }
  }

  void _onPlaces(List<SavedPlace> places) {
    final selected = state.destination?.saved;
    final current = selected == null
        ? null
        : places.where((p) => p.id == selected.id).firstOrNull;
    final next = state.copyWith(places: places);
    emit(
      selected == null
          ? next
          : next.withDestination(state.destination!.withSaved(current)),
    );
  }

  /// The card's Continue: Android's popup, once.
  Future<void> continueToPermission() async {
    await _workspace.settings.write(SettingsStore.locationExplained, '1');
    await askForLocation();
  }

  Future<void> notNow() async {
    await _workspace.settings.write(SettingsStore.locationExplained, '1');
    emit(state.copyWith(location: LocationStatus.denied));
  }

  Future<void> askForLocation() async {
    final access = await _location.request();
    if (isClosed) return;
    if (access == LocationAccess.granted) {
      await _track();
    } else {
      emit(state.copyWith(location: LocationStatus.denied));
    }
  }

  Future<void> _track() async {
    emit(state.copyWith(location: LocationStatus.granted));
    await _positions?.cancel();
    _positions = _location.positions().listen(
      (point) => emit(state.copyWith(me: point)),
    );
    final here = await _location.current();
    if (here != null && !isClosed) emit(state.copyWith(me: here));
  }

  /// A search result, a recent or a saved place. Searched places become recents.
  void select(Destination destination) {
    final saved = destination.saved ?? _savedAt(destination.point);
    emit(state.withDestination(destination.withSaved(saved)));
    if (destination.saved == null) {
      unawaited(_workspace.recents.add(destination));
    }
  }

  /// A long press on the map: the pin is named after the nearest place.
  Future<void> dropPin(GeoPoint point) async {
    emit(state.withDestination(Destination(point: point), resolving: true));
    Destination? found;
    try {
      found = await _nominatim.reverse(point);
    } on Exception {
      found = null;
    }
    if (isClosed || state.destination?.point != point) return;
    emit(state.withDestination(found ?? Destination(point: point)));
  }

  void clear() => emit(state.withDestination(null));

  /// Saves the destination as a new place, or renames the one it is.
  Future<void> save({required String name, required PlaceKind kind}) async {
    final destination = state.destination;
    if (destination == null) return;
    final saved = destination.saved;
    if (saved != null) {
      await _workspace.places.update(saved.copyWith(name: name, kind: kind));
    } else {
      final place = await _workspace.places.add(
        destination,
        name: name,
        kind: kind,
      );
      if (!isClosed) emit(state.withDestination(destination.withSaved(place)));
    }
  }

  Future<void> updatePlace(SavedPlace place) => _workspace.places.update(place);

  Future<void> removePlace(SavedPlace place) =>
      _workspace.places.remove(place.id);

  SavedPlace? _savedAt(GeoPoint point) =>
      state.places.where((p) => p.point.distanceTo(point) < 25).firstOrNull;

  @override
  Future<void> close() async {
    await _places?.cancel();
    await _positions?.cancel();
    return super.close();
  }
}
