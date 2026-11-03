import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/data/recents_repository.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/search/nominatim.dart';

enum LocationStatus {
  checking,

  /// First time: the card explains why before Android asks.
  explain,
  denied,
  granted,
}

/// A one-off message for the screen.
enum HomeNotice { arrived, guideFailed, needsLocation }

class HomeState extends Equatable {
  const HomeState({
    this.places = const [],
    this.location = LocationStatus.checking,
    this.me,
    this.destination,
    this.resolving = false,
    this.ride,
    this.status,
    this.near,
    this.explainNotifications = false,
    this.makerSteps,
    this.notice,
  });

  final List<SavedPlace> places;
  final LocationStatus location;
  final GeoPoint? me;
  final Destination? destination;

  /// A dropped pin is being named after the nearest place.
  final bool resolving;

  /// The running guide: Home is in ride mode while there is one.
  final GuideRide? ride;

  /// The guide's latest news; null until its first GPS fix.
  final GuideStatus? status;

  /// The area you are passing, for "Now near".
  final Destination? near;

  /// The first Start: a card says why before Android asks for notifications.
  final bool explainNotifications;

  /// The maker's battery steps, shown once after the first Start.
  final PhoneMaker? makerSteps;
  final HomeNotice? notice;

  static const _keep = Object();

  /// Fields left out keep their value; nullable ones take an explicit null.
  HomeState copyWith({
    List<SavedPlace>? places,
    LocationStatus? location,
    GeoPoint? me,
    Object? destination = _keep,
    bool? resolving,
    Object? ride = _keep,
    Object? status = _keep,
    Object? near = _keep,
    bool? explainNotifications,
    Object? makerSteps = _keep,
    Object? notice = _keep,
  }) => HomeState(
    places: places ?? this.places,
    location: location ?? this.location,
    me: me ?? this.me,
    destination: identical(destination, _keep)
        ? this.destination
        : destination as Destination?,
    resolving: resolving ?? this.resolving,
    ride: identical(ride, _keep) ? this.ride : ride as GuideRide?,
    status: identical(status, _keep) ? this.status : status as GuideStatus?,
    near: identical(near, _keep) ? this.near : near as Destination?,
    explainNotifications: explainNotifications ?? this.explainNotifications,
    makerSteps: identical(makerSteps, _keep)
        ? this.makerSteps
        : makerSteps as PhoneMaker?,
    notice: identical(notice, _keep) ? this.notice : notice as HomeNotice?,
  );

  HomeState withDestination(
    Destination? destination, {
    bool resolving = false,
  }) => copyWith(destination: destination, resolving: resolving);

  @override
  List<Object?> get props => [
    places,
    location,
    me,
    destination,
    resolving,
    ride,
    status,
    near,
    explainNotifications,
    makerSteps,
    notice,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._workspace,
    this._location,
    this._nominatim,
    this._guide, {
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now,
       super(const HomeState());

  final Workspace _workspace;
  final LocationService _location;
  final Nominatim _nominatim;
  final GuideService _guide;
  final DateTime Function() _clock;
  StreamSubscription<List<SavedPlace>>? _places;
  StreamSubscription<GeoPoint>? _positions;
  StreamSubscription<GuideEvent>? _guideEvents;

  /// The guide waiting on the notifications card.
  GuideRide? _pending;
  DateTime? _nearAt;

  /// "Now near" looks the area up about once a minute.
  static const nearEvery = Duration(minutes: 1);

  Future<void> start() async {
    _places = _workspace.places.watch().listen(_onPlaces);
    _guideEvents = _guide.events.listen(_onGuide);
    // A guide outlives the app's screens: back in ride mode where it is.
    final running = await _guide.running();
    if (isClosed) return;
    if (running != null) {
      emit(state.copyWith(ride: running, destination: running.destination));
    }
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
    final destination = state.destination;
    final selected = destination?.saved;
    final next = state.copyWith(places: places);
    if (destination == null) {
      emit(next);
      return;
    }
    final current = selected == null
        ? _savedAt(destination.point, places)
        : places.where((p) => p.id == selected.id).firstOrNull;
    emit(next.copyWith(destination: destination.withSaved(current)));
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
    if (state.ride != null) return;
    final saved = destination.saved ?? _savedAt(destination.point);
    emit(state.withDestination(destination.withSaved(saved)));
    if (destination.saved == null) {
      unawaited(_workspace.recents.add(destination));
    }
  }

  /// A long press on the map: the pin is named after the nearest place.
  Future<void> dropPin(GeoPoint point) async {
    if (state.ride != null) return;
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

  void clear() {
    if (state.ride == null) emit(state.withDestination(null));
  }

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

  /// Start, in the destination panel. [title] is the stop's name as the panel
  /// shows it, in the app's [language], for the notifications.
  Future<void> startGuide({
    required String title,
    required String language,
  }) async {
    final destination = state.destination;
    if (destination == null || state.ride != null) return;
    _pending = GuideRide(
      to: destination.point,
      title: title,
      names: destination.names,
      area: destination.area,
      language: language,
    );
    if (state.location != LocationStatus.granted) {
      await askForLocation();
      if (isClosed) return;
      if (state.location != LocationStatus.granted) {
        _pending = null;
        emit(state.copyWith(notice: HomeNotice.needsLocation));
        return;
      }
    }
    final explained =
        await _workspace.settings.read(SettingsStore.notificationsExplained) !=
        null;
    if (!explained && !await _guide.notificationsAllowed()) {
      if (!isClosed) emit(state.copyWith(explainNotifications: true));
      return;
    }
    await _begin();
  }

  /// The notifications card's Continue: Android's popup, then the guide.
  Future<void> continueToNotifications() async {
    await _workspace.settings.write(SettingsStore.notificationsExplained, '1');
    await _guide.askForNotifications();
    await _begin();
  }

  /// The notifications card's "Not now": the guide still buzzes.
  Future<void> skipNotifications() async {
    await _workspace.settings.write(SettingsStore.notificationsExplained, '1');
    await _begin();
  }

  Future<void> _begin() async {
    final ride = _pending;
    _pending = null;
    if (ride == null || isClosed) return;
    final first =
        await _workspace.settings.read(SettingsStore.batteryExplained) == null;
    if (first) {
      await _workspace.settings.write(SettingsStore.batteryExplained, '1');
      await _guide.askToRunInBackground();
    }
    final started = await _guide.start(ride);
    if (isClosed) return;
    if (!started) {
      emit(
        state.copyWith(
          explainNotifications: false,
          notice: HomeNotice.guideFailed,
        ),
      );
      return;
    }
    final maker = first ? await _guide.maker() : PhoneMaker.other;
    if (isClosed) return;
    _nearAt = null;
    emit(
      state.copyWith(
        explainNotifications: false,
        ride: ride,
        status: null,
        near: null,
        makerSteps: maker == PhoneMaker.other ? null : maker,
      ),
    );
  }

  /// End, on the ride board: back to the destination panel.
  Future<void> endGuide() async {
    await _guide.end();
    if (!isClosed) emit(state.copyWith(ride: null, status: null, near: null));
  }

  void _onGuide(GuideEvent event) {
    if (state.ride == null) return;
    switch (event) {
      case GuideUpdate(:final status):
        emit(state.copyWith(status: status));
        if (status.at case final at?) unawaited(_lookNear(at));
      case GuideEnded(:final arrived):
        emit(
          state.copyWith(
            ride: null,
            status: null,
            near: null,
            destination: arrived ? null : state.destination,
            notice: arrived ? HomeNotice.arrived : null,
          ),
        );
    }
  }

  Future<void> _lookNear(GeoPoint at) async {
    final now = _clock();
    final last = _nearAt;
    if (last != null && now.difference(last) < nearEvery) return;
    _nearAt = now;
    Destination? near;
    try {
      near = await _nominatim.reverse(at, zoom: 14);
    } on Exception {
      return;
    }
    if (isClosed || state.ride == null || near == null) return;
    emit(state.copyWith(near: near));
  }

  Future<void> openMakerSettings() => _guide.openMakerSettings();

  void makerStepsSeen() => emit(state.copyWith(makerSteps: null));

  void noticed() => emit(state.copyWith(notice: null));

  SavedPlace? _savedAt(GeoPoint point, [List<SavedPlace>? places]) =>
      (places ?? state.places)
          .where((p) => p.point.distanceTo(point) < 25)
          .firstOrNull;

  @override
  Future<void> close() async {
    await _places?.cancel();
    await _positions?.cancel();
    await _guideEvents?.cancel();
    return super.close();
  }
}
