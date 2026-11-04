import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart'
    hide NotificationVisibility;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/guide_engine.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/l10n/app_localizations.dart';
import 'package:vibration/vibration.dart';

/// Where the running guide's ride is kept, for the service and the app.
const rideKey = 'guide.ride';

/// Asks the ride service for its latest status.
const askStatus = 'status';

/// The End button on the guide's notification.
const endButton = 'end';

/// The Keep button, while the guide asks "Still going to (stop)?"; also what
/// the app sends when Keep is tapped on the ride board.
const keepButton = 'keep';

/// The ride service's entry point. flutter_foreground_task runs it in an
/// isolate of its own, which lives on when the app is swiped away.
@pragma('vm:entry-point')
void startRideTask() => FlutterForegroundTask.setTaskHandler(RideTask());

/// The guide inside the ride service (docs/PLAN.md, The guide): a GPS fix
/// every 5 seconds into the engine, then the buzz, the alert on the lock
/// screen, the ongoing notification and the app's ride board.
class RideTask extends TaskHandler {
  static const _alertId = 7;
  static const _amber = Color(0xFFFFB020);

  final _alerts = FlutterLocalNotificationsPlugin();
  GuideRide? _ride;
  GuideEngine? _engine;
  AppLocalizations? _l;
  StreamSubscription<Position>? _fixes;
  GuideStatus? _status;
  String? _shown;
  var _arrived = false;
  var _gaveUp = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final saved = await FlutterForegroundTask.getData<String>(key: rideKey);
    final ride = saved == null ? null : GuideRide.fromJson(jsonDecode(saved));
    if (ride == null) {
      await FlutterForegroundTask.stopService();
      return;
    }
    _ride = ride;
    _engine = GuideEngine(ride);
    if (kDebugMode) debugPrint('guide: started to ${ride.title}');
    _l = lookupAppLocalizations(Locale(ride.language));
    await _alerts.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    _follow();
  }

  void _follow() {
    _fixes = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: const Duration(seconds: 5),
      ),
    ).listen(_onFix, onError: (Object _) => _lost(), onDone: _lost);
  }

  /// Location went off or away: the next beat follows again.
  void _lost() {
    unawaited(_fixes?.cancel());
    _fixes = null;
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_fixes == null && _engine != null) _follow();
  }

  Future<void> _onFix(Position position) async {
    final ride = _ride;
    final l = _l;
    final step = _engine?.update(
      RideFix(
        GeoPoint(position.latitude, position.longitude),
        position.timestamp,
        accuracy: position.accuracy,
      ),
    );
    if (kDebugMode) {
      debugPrint(
        'guide: fix ${position.accuracy.round()} m accurate, '
        '${step == null ? 'ignored' : '${step.status.metres.round()} m left, '
                  '${step.status.left?.inSeconds ?? '-'} s, '
                  '${step.status.phase.name}${step.alert == null ? '' : ', ${step.alert}'}'}',
      );
    }
    if (ride == null || l == null || step == null) return;
    final status = _status = step.status;
    FlutterForegroundTask.sendDataToMain(statusMessage(status));
    switch (step.alert) {
      case StageDue(:final index):
        final last = index == ride.stages.length - 1;
        await _alert(
          last ? l.getOffNext : l.getReady,
          ride.stages[index].pattern.buzz.repeated(2),
          status,
        );
      case StopPassed():
        await _alert(l.passedStop, passedBuzz, status);
      case Arrived():
        _arrived = true;
        await _buzz(arrivedBuzz);
        await FlutterForegroundTask.stopService();
        return;
      case StillGoing():
        await _alert(
          l.stillGoing(ride.title),
          AlertPattern.gentleDoubleTap.buzz.repeated(2),
          status,
        );
      case GaveUp():
        _gaveUp = true;
        await _buzz(arrivedBuzz);
        await FlutterForegroundTask.stopService();
        return;
      case null:
        break;
    }
    await _show(status);
  }

  /// Keep, in the notification or on the ride board.
  Future<void> _keepGoing() async {
    final status = _status;
    if (status == null || !status.asking) return;
    _engine?.keepGoing(DateTime.now());
    final kept = GuideStatus(
      metres: status.metres,
      progress: status.progress,
      left: status.left,
      phase: status.phase,
      at: status.at,
    );
    _status = kept;
    await _alerts.cancel(id: _alertId);
    FlutterForegroundTask.sendDataToMain(statusMessage(kept));
    await _show(kept);
  }

  Future<void> _buzz(Buzz buzz) async {
    if (!await Vibration.hasVibrator()) return;
    await Vibration.vibrate(
      pattern: buzz.timings,
      intensities: buzz.amplitudes,
    );
  }

  /// The buzz, and an alert on the lock screen: silent, and the screen stays
  /// off.
  Future<void> _alert(String title, Buzz buzz, GuideStatus status) async {
    await _buzz(buzz);
    await _alerts.show(
      id: _alertId,
      title: title,
      body: _to(status),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'alerts',
          _l!.channelAlerts,
          importance: Importance.high,
          priority: Priority.high,
          playSound: false,
          enableVibration: false,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.navigation,
          icon: 'ic_notification',
          color: _amber,
        ),
      ),
    );
  }

  /// The ongoing notification, updated when its words change.
  Future<void> _show(GuideStatus status) async {
    final l = _l!;
    final to = _to(status);
    final left = status.left;
    final (title, text) = switch (status.phase) {
      _ when status.asking => (l.stillGoing(_ride!.title), to),
      GuidePhase.riding => (
        to,
        left == null ? '' : l.minutesLeft(wholeMinutes(left)),
      ),
      GuidePhase.getOff => (l.getOffNext, to),
      GuidePhase.passed => (l.passedStop, to),
    };
    final shown = '$title\n$text\n${status.asking}';
    if (shown == _shown) return;
    _shown = shown;
    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationButtons: [
        if (status.asking) NotificationButton(id: keepButton, text: l.keep),
        NotificationButton(id: endButton, text: l.end),
      ],
    );
  }

  /// "2.4 km to Colombo Fort".
  String _to(GuideStatus status) {
    final l = _l!;
    final away = shortDistance(status.metres);
    return l.distanceTo(
      away.km ? l.distanceKm(away.value) : l.distanceM(away.value),
      _ride!.title,
    );
  }

  @override
  void onReceiveData(Object data) {
    final status = _status;
    if (data == askStatus && status != null) {
      FlutterForegroundTask.sendDataToMain(statusMessage(status));
    } else if (data == keepButton) {
      unawaited(_keepGoing());
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == endButton) unawaited(FlutterForegroundTask.stopService());
    if (id == keepButton) unawaited(_keepGoing());
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    if (kDebugMode) debugPrint('guide: ended, arrived: $_arrived');
    _lost();
    // Ending stops a buzz still playing; arriving lets its tap finish.
    if (!_arrived) await Vibration.cancel();
    await _alerts.cancel(id: _alertId);
    await FlutterForegroundTask.removeData(key: rideKey);
    FlutterForegroundTask.sendDataToMain(
      endedMessage(arrived: _arrived, gaveUp: _gaveUp),
    );
  }
}

/// The service's messages to the app.
Map<String, Object?> statusMessage(GuideStatus status) => {
  'type': 'status',
  'status': status.toJson(),
};

Map<String, Object?> endedMessage({
  required bool arrived,
  bool gaveUp = false,
}) => {'type': 'ended', 'arrived': arrived, 'gaveUp': gaveUp};
