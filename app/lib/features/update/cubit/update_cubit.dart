import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/update/updates.dart';

enum UpdatePhase {
  idle,
  checking,
  upToDate,

  /// A newer version is out: the Home banner shows.
  available,
  downloading,

  /// Android's page to let Hopin install apps opened instead of the
  /// installer.
  needsPermission,
  checkFailed,
  downloadFailed,
}

class UpdateState extends Equatable {
  const UpdateState({
    required this.installed,
    this.phase = UpdatePhase.idle,
    this.latest,
    this.progress = 0,
  });

  /// This build; 0 for builds that don't update.
  final int installed;
  final UpdatePhase phase;
  final Release? latest;

  /// The download, from 0 to 1.
  final double progress;

  /// Whether the Home banner shows.
  bool get offered => switch (phase) {
    UpdatePhase.available ||
    UpdatePhase.downloading ||
    UpdatePhase.needsPermission ||
    UpdatePhase.downloadFailed => latest != null,
    _ => false,
  };

  UpdateState copyWith({
    UpdatePhase? phase,
    Release? latest,
    double? progress,
  }) => UpdateState(
    installed: installed,
    phase: phase ?? this.phase,
    latest: latest ?? this.latest,
    progress: progress ?? this.progress,
  );

  @override
  List<Object?> get props => [installed, phase, latest, progress];
}

/// New versions from GitHub Releases (docs/PLAN.md, Settings and updates):
/// looked for when Hopin opens, at most every [every], or now from Settings;
/// downloaded inside Hopin, then handed to Android's installer.
class UpdateCubit extends Cubit<UpdateState> {
  UpdateCubit(this._updates, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(UpdateState(installed: _updates.installed));

  final UpdateService _updates;
  final DateTime Function() _clock;
  DateTime? _checkedAt;
  String? _file;

  static const every = Duration(hours: 6);

  /// Looks for a newer version; [now] skips the wait and reports failures
  /// (Settings, Check).
  Future<void> check({bool now = false}) async {
    if (state.installed <= 0 || state.phase == UpdatePhase.downloading) return;
    final last = _checkedAt;
    if (!now && last != null && _clock().difference(last) < every) return;
    _checkedAt = _clock();
    if (now) emit(state.copyWith(phase: UpdatePhase.checking));
    Release? latest;
    try {
      latest = await _updates.latest();
    } on Exception {
      if (!isClosed && now) {
        emit(state.copyWith(phase: UpdatePhase.checkFailed));
      }
      return;
    }
    if (isClosed) return;
    if (latest != null && latest.build > state.installed) {
      if (latest != state.latest) _file = null;
      if (!state.offered || latest != state.latest) {
        emit(state.copyWith(phase: UpdatePhase.available, latest: latest));
      }
    } else {
      emit(state.copyWith(phase: UpdatePhase.upToDate));
    }
  }

  /// The banner's Update: downloads once, then opens Android's installer.
  Future<void> update() async {
    final release = state.latest;
    if (release == null || state.phase == UpdatePhase.downloading) return;
    var file = _file;
    if (file == null) {
      emit(state.copyWith(phase: UpdatePhase.downloading, progress: 0));
      var shown = 0;
      try {
        file = await _updates.download(release, (progress) {
          final percent = (progress * 100).floor();
          if (percent == shown || isClosed) return;
          shown = percent;
          emit(state.copyWith(progress: progress));
        });
      } on Exception {
        if (!isClosed) {
          emit(state.copyWith(phase: UpdatePhase.downloadFailed));
        }
        return;
      }
      _file = file;
    }
    final opened = await _updates.install(file);
    if (isClosed) return;
    emit(
      state.copyWith(
        phase: opened ? UpdatePhase.available : UpdatePhase.needsPermission,
        progress: 1,
      ),
    );
  }
}
