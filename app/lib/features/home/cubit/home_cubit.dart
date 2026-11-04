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
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/core/share/share.dart';
import 'package:hopin/core/share/shares.dart';

enum LocationStatus {
  checking,

  /// First time: the card explains why before Android asks.
  explain,
  denied,
  granted,
}

/// A one-off message for the screen.
enum HomeNotice { arrived, gaveUp, guideFailed, needsLocation }

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
    this.question = false,
    this.offerDetection = false,
    this.sharing,
    this.noticedSince,
    this.other,
    this.watching = false,
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

  /// The ride service asks "On a bus?": its card shows.
  final bool question;

  /// The one-time card offering ride detection.
  final bool offerDetection;

  /// This ride's open share (docs/PLAN.md, Sharing and stops).
  final String? sharing;

  /// A bus ride with no guide is on: Home shows its slim bar.
  final DateTime? noticedSince;

  /// The other rider's open share: its card, then Watch.
  final LiveShare? other;
  final bool watching;

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
    bool? question,
    bool? offerDetection,
    Object? sharing = _keep,
    Object? noticedSince = _keep,
    Object? other = _keep,
    bool? watching,
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
    question: question ?? this.question,
    offerDetection: offerDetection ?? this.offerDetection,
    sharing: identical(sharing, _keep) ? this.sharing : sharing as String?,
    noticedSince: identical(noticedSince, _keep)
        ? this.noticedSince
        : noticedSince as DateTime?,
    other: identical(other, _keep) ? this.other : other as LiveShare?,
    watching: watching ?? this.watching,
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
    question,
    offerDetection,
    sharing,
    noticedSince,
    other,
    watching,
  ];
}

class HomeCubit extends Cubit<HomeState> {
  HomeCubit(
    this._workspace,
    this._location,
    this._nominatim,
    this._guide, {
    required Shares shares,
    DateTime Function()? clock,
  }) : _shareSource = shares,
       _clock = clock ?? DateTime.now,
       super(const HomeState());

  final Workspace _workspace;
  final LocationService _location;
  final Nominatim _nominatim;
  final GuideService _guide;
  final Shares _shareSource;
  final DateTime Function() _clock;
  StreamSubscription<List<SavedPlace>>? _places;
  StreamSubscription<GeoPoint>? _positions;
  StreamSubscription<GuideEvent>? _guideEvents;
  StreamSubscription<List<LiveShare>>? _shares;

  /// Shares whose card was put away with Not now.
  final _dismissed = <String>{};

  /// A share silent this long is left out (its service stopped, say).
  static const staleAfter = Duration(minutes: 15);

  /// The guide waiting on the notifications card.
  GuideRide? _pending;
  DateTime? _nearAt;

  /// "Now near" looks the area up about once a minute.
  static const nearEvery = Duration(minutes: 1);

  Future<void> start() async {
    // Rides the service finished while Hopin was closed.
    for (final ride in await _guide.pendingRides()) {
      await _keepRide(ride);
    }
    if (isClosed) return;
    _places = _workspace.places.watch().listen(_onPlaces);
    _guideEvents = _guide.events.listen(_onGuide);
    // Only riders may look for shares; for anyone else the listen fails.
    _shares = _shareSource.watchOpen().listen(
      _onShares,
      onError: (Object _) {},
    );
    // A guide outlives the app's screens: back in ride mode where it is.
    final running = await _guide.running();
    if (isClosed) return;
    if (running != null) {
      emit(state.copyWith(ride: running, destination: running.destination));
    }
    // No ride service: a share it left open (stopped by the phone) ends.
    if (!await _guide.serviceRunning()) {
      unawaited(
        _shareSource.closeLeftOpen(_workspace.uid).catchError((Object _) {}),
      );
    }
    if (isClosed) return;
    final explained =
        await _workspace.settings.read(SettingsStore.locationExplained) != null;
    final access = await _location.check();
    if (isClosed) return;
    if (access == LocationAccess.granted) {
      await _track();
      final offered =
          await _workspace.settings.read(SettingsStore.detectionOffered) !=
          null;
      if (!offered && !(await _guide.detection()).on && !isClosed) {
        emit(state.copyWith(offerDetection: true));
      }
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
  Future<void> save({
    required String name,
    required PlaceKind kind,
    bool shareRides = false,
  }) async {
    final destination = state.destination;
    if (destination == null) return;
    final saved = destination.saved;
    if (saved != null) {
      await _workspace.places.update(
        saved.copyWith(name: name, kind: kind, shareRides: shareRides),
      );
    } else {
      final place = await _workspace.places.add(
        destination,
        name: name,
        kind: kind,
        shareRides: shareRides,
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
      stages: await _workspace.appSettings.stages(),
      language: language,
      share: destination.saved?.shareRides ?? false,
    );
    if (isClosed) return;
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
  /// Keep, on the ride board while the guide asks "Still going?".
  Future<void> keepGoing() => _guide.keepGoing();

  Future<void> endGuide() async {
    await _guide.end();
    if (!isClosed) emit(state.copyWith(ride: null, status: null, near: null));
  }

  void _onGuide(GuideEvent event) {
    switch (event) {
      case RideLogged(:final ride):
        unawaited(_keepRide(ride));
        return;
      case ShareChanged(:final id):
        emit(state.copyWith(sharing: id));
        return;
      case RideNoticed(:final since):
        if (state.ride == null) emit(state.copyWith(noticedSince: since));
        return;
      case RideQuestion():
        emit(state.copyWith(question: true));
        return;
      case RideAnswered():
        emit(state.copyWith(question: false));
        return;
      case GuideStarted(:final ride):
        _nearAt = null;
        emit(
          state.copyWith(
            question: false,
            noticedSince: null,
            ride: ride,
            status: null,
            near: null,
            destination: ride.destination,
          ),
        );
        return;
      case GuideEnded():
        // Whatever ended, the ride's share and bar went with it.
        emit(state.copyWith(sharing: null, noticedSince: null));
        if (state.ride == null) return;
      case GuideUpdate():
        if (state.ride == null) return;
    }
    switch (event) {
      case GuideUpdate(:final status):
        emit(state.copyWith(status: status));
        if (status.at case final at?) unawaited(_lookNear(at));
      case GuideEnded(:final arrived, :final gaveUp):
        emit(
          state.copyWith(
            ride: null,
            status: null,
            near: null,
            destination: arrived ? null : state.destination,
            notice: arrived
                ? HomeNotice.arrived
                : gaveUp
                ? HomeNotice.gaveUp
                : null,
          ),
        );
      case RideQuestion() ||
          RideAnswered() ||
          GuideStarted() ||
          RideLogged() ||
          ShareChanged() ||
          RideNoticed():
        break;
    }
  }

  Future<void> _keepRide(RideRecord ride) async {
    await _workspace.rides.save(ride);
    await _guide.forgetPendingRide(ride.id);
    if (ride.unnamed) unawaited(_workspace.namer(_nominatim).nameMissing());
  }

  /// Share, on the ride board or the ride bar: the link to send. A ride
  /// already shared keeps its link.
  Future<String> share() async {
    final open = state.sharing;
    if (open != null) return shareLink(open);
    final id = newShareId();
    emit(state.copyWith(sharing: id));
    await _guide.share(id);
    return shareLink(id);
  }

  Future<void> stopSharing() async {
    await _guide.stopSharing();
    if (!isClosed) emit(state.copyWith(sharing: null));
  }

  /// End, on the ride bar of a noticed ride.
  Future<void> endRide() async {
    await _guide.end();
    if (!isClosed) emit(state.copyWith(noticedSince: null, sharing: null));
  }

  void _onShares(List<LiveShare> open) {
    final now = _clock();
    final others =
        open
            .where(
              (share) =>
                  share.uid != _workspace.uid &&
                  !_dismissed.contains(share.id) &&
                  (share.updatedAt == null ||
                      now.difference(share.updatedAt!) < staleAfter),
            )
            .toList()
          ..sort((a, b) => (b.updatedAt ?? now).compareTo(a.updatedAt ?? now));
    final other = others.firstOrNull;
    emit(
      state.copyWith(
        other: other,
        watching: state.watching && other?.id == state.other?.id,
      ),
    );
  }

  /// Watch, on the other rider's card: they show on the map.
  void watch() {
    if (state.other != null) emit(state.copyWith(watching: true));
  }

  void closeWatch() => emit(state.copyWith(watching: false));

  /// Not now, on the other rider's card: this share's card goes.
  void dismissShare() {
    final other = state.other;
    if (other == null) return;
    _dismissed.add(other.id);
    emit(state.copyWith(other: null, watching: false));
  }

  /// An answer on the "On a bus?" card (ride_task.dart's button IDs).
  Future<void> answer(String button) async {
    emit(state.copyWith(question: false));
    await _guide.answer(button);
  }

  /// The one-time card's Turn on: Android's two permissions, then on.
  Future<void> turnOnDetection(String language) async {
    await _workspace.settings.write(SettingsStore.detectionOffered, '1');
    emit(state.copyWith(offerDetection: false));
    await _guide.turnOnDetection(language);
  }

  Future<void> detectionNotNow() async {
    await _workspace.settings.write(SettingsStore.detectionOffered, '1');
    emit(state.copyWith(offerDetection: false));
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
    await _shares?.cancel();
    return super.close();
  }
}
