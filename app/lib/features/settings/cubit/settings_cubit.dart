import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/app/workspace.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';

class SettingsState extends Equatable {
  const SettingsState({
    this.places = const [],
    this.stages = defaultStages,
    this.notificationsOn,
    this.runsInBackground,
    this.maker = PhoneMaker.other,
    this.detection,
  });

  final List<SavedPlace> places;

  /// Outermost first; the last is "Get off next".
  final List<GuideStage> stages;

  /// Null until the phone has answered.
  final bool? notificationsOn;
  final bool? runsInBackground;
  final PhoneMaker maker;

  /// Null until the phone has answered.
  final Detection? detection;

  SettingsState copyWith({
    List<SavedPlace>? places,
    List<GuideStage>? stages,
    bool? notificationsOn,
    bool? runsInBackground,
    PhoneMaker? maker,
    Detection? detection,
  }) => SettingsState(
    places: places ?? this.places,
    stages: stages ?? this.stages,
    notificationsOn: notificationsOn ?? this.notificationsOn,
    runsInBackground: runsInBackground ?? this.runsInBackground,
    maker: maker ?? this.maker,
    detection: detection ?? this.detection,
  );

  @override
  List<Object?> get props => [
    places,
    stages,
    notificationsOn,
    runsInBackground,
    maker,
    detection,
  ];
}

/// The Settings page (docs/PLAN.md, Settings and updates). It reads the
/// local database and asks the phone; the language and stages go through
/// [Workspace.appSettings], which syncs them.
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit(this._workspace, this._guide) : super(const SettingsState());

  final Workspace _workspace;
  final GuideService _guide;
  StreamSubscription<List<SavedPlace>>? _places;
  StreamSubscription<List<GuideStage>>? _stages;

  Future<void> start() async {
    _places = _workspace.places.watch().listen(
      (places) => emit(state.copyWith(places: places)),
    );
    _stages = _workspace.appSettings.watchStages().listen(
      (stages) => emit(state.copyWith(stages: stages)),
    );
    await checkPhone();
  }

  /// Notifications and the background state, which change in Android's
  /// settings (so again when Hopin comes back to the front).
  Future<void> checkPhone() async {
    final (notifications, background, maker, detection) = await (
      _guide.notificationsAllowed(),
      _guide.runsInBackground(),
      _guide.maker(),
      _guide.detection(),
    ).wait;
    if (isClosed) return;
    emit(
      state.copyWith(
        notificationsOn: notifications,
        runsInBackground: background,
        maker: maker,
        detection: detection,
      ),
    );
  }

  /// A place dragged from [from] to [to] (its index once moved).
  Future<void> reorder(int from, int to) async {
    final places = [...state.places];
    places.insert(to, places.removeAt(from));
    emit(state.copyWith(places: places));
    await _workspace.places.reorder(places);
  }

  Future<void> updatePlace(SavedPlace place) => _workspace.places.update(place);

  Future<void> removePlace(SavedPlace place) =>
      _workspace.places.remove(place.id);

  Future<void> setLanguage(String code) =>
      _workspace.appSettings.setLanguage(code);

  /// Saves [stage] in place of stage [index], or as a new one without it.
  Future<void> saveStage(int? index, GuideStage stage) {
    final stages = [...state.stages];
    if (index == null) {
      stages.add(stage);
    } else {
      stages[index] = stage;
    }
    return _setStages(stages);
  }

  Future<void> removeStage(int index) async {
    if (state.stages.length <= 1) return;
    await _setStages([...state.stages]..removeAt(index));
  }

  /// Shown at once, so a quick second edit builds on the first.
  Future<void> _setStages(List<GuideStage> stages) async {
    final tidy = tidyStages(stages);
    if (tidy.isEmpty) return;
    emit(state.copyWith(stages: tidy));
    await _workspace.appSettings.setStages(tidy);
  }

  /// A new stage: the farthest distance not in use, a gentle double tap.
  GuideStage nextStage() {
    final used = {for (final stage in state.stages) stage.metres};
    return GuideStage(
      stageDistances.firstWhere((m) => !used.contains(m)),
      AlertPattern.gentleDoubleTap,
    );
  }

  /// "Try it": the pattern as the alert plays it.
  Future<void> tryPattern(AlertPattern pattern) =>
      _guide.play(pattern.buzz.repeated(2));

  Future<void> turnOnNotifications() async {
    if (!await _guide.askForNotifications()) await _guide.openAppSettings();
    await checkPhone();
  }

  /// Android's background popup, then the phone's own state.
  Future<void> askToRunInBackground() async {
    await _guide.askToRunInBackground();
    await checkPhone();
  }

  Future<void> openMakerSettings() => _guide.openMakerSettings();

  /// The Notice bus rides switch.
  Future<void> setDetection({
    required bool on,
    required String language,
  }) async {
    if (on) {
      await _guide.turnOnDetection(language);
    } else {
      await _guide.turnOffDetection();
    }
    await checkPhone();
  }

  /// Test builds: watch a ride now, without a vehicle.
  Future<void> detectNow() => _guide.detectNow();

  @override
  Future<void> close() async {
    await _places?.cancel();
    await _stages?.cancel();
    return super.close();
  }
}
