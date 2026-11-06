import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/guide_engine.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_config.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/core/share/share.dart';
import 'package:hopin/core/share/shares.dart';
import 'package:hopin/firebase_options.dart';
import 'package:hopin/l10n/app_localizations.dart';
import 'package:hopin/l10n/time_left.dart';
import 'package:vibration/vibration.dart';

/// Where the running guide's ride is kept, for the service and the app.
const rideKey = 'guide.ride';

/// The places, stages and language the service needs when it wakes for a
/// ride with Hopin closed (kept up to date by the app).
const configKey = 'ride.config';

/// A finished ride waiting for the app, one key per ride.
const pendingRidePrefix = 'ride.pending.';

/// When Android last said the phone left a vehicle (written natively).
const vehicleExitKey = 'vehicle.exitAt';

/// Asks the ride service for its latest status.
const askStatus = 'status';

/// The End button on the guide's notification.
const endButton = 'end';

/// The Keep button, while the guide asks "Still going to (stop)?"; also what
/// the app sends when Keep is tapped on the ride board.
const keepButton = 'keep';

/// The "On a bus?" answers, from the notification or the app's card.
const yesButton = 'yes';
const notBusButton = 'notbus';
String placeButton(int index) => 'place$index';

/// From the app: a guide was saved under [rideKey]; guide to it.
const guideNow = 'guide';

/// Set when the ride service stops; the native backstop keeps quiet until
/// the rider is on foot again (RideDetection.kt), so Not a bus and End aren't
/// undone in the same vehicle.
const quietKey = 'ride.quiet';

/// From the app: the ride's bus ({tagCommand: RouteTag JSON, or null}).
const tagCommand = 'tag';

/// From the app: share the ride under this id ({shareCommand: id}), or stop.
const shareCommand = 'share';
const stopShareCommand = 'stopShare';

/// The ride service's entry point. flutter_foreground_task runs it in an
/// isolate of its own, which lives on when the app is swiped away.
@pragma('vm:entry-point')
void startRideTask() => FlutterForegroundTask.setTaskHandler(RideTask());

/// The ride service (docs/PLAN.md, The guide and Ride detection). It logs
/// every ride through [BusLogic]. Started by the app it guides at once;
/// woken by Android's vehicle transition it first watches the ride (a fix
/// every 10 seconds) and asks "On a bus?" once it looks like one: a place
/// button guides there, Not a bus stops. Everything it says is on its one
/// notification, which changes in place, with a buzz where it matters.
class RideTask extends TaskHandler {
  /// This long after Android says the vehicle was left, and the vehicle
  /// part last moving, the ride is over (walking on doesn't count); without
  /// moving at all this long, too.
  static const _offAfter = Duration(minutes: 2);
  static const _stillAfter = Duration(minutes: 15);

  /// Rides shorter than these aren't kept (a false start).
  static const _keepAfter = Duration(minutes: 2);
  static const _keepAfterMetres = 300.0;

  final _logic = BusLogic();
  final _rideId =
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${math.Random().nextInt(1 << 30).toRadixString(36)}';
  var _config = const RideConfig();
  late final DateTime _startedAt;
  GuideRide? _ride;
  GuideEngine? _engine;
  AppLocalizations? _l;
  StreamSubscription<Position>? _fixes;
  var _interval = const Duration(seconds: 10);
  GuideStatus? _status;
  String? _shown;
  RideVerdict? _verdict;
  var _asking = false;

  /// A guide's "Get ready" stage came: its notification says so until
  /// "Get off next".
  var _ready = false;
  var _arrived = false;
  var _gaveUp = false;

  /// The bus the ride is, as tagged in the app or picked before Start.
  RouteTag? _tag;

  /// The open share, if any (docs/PLAN.md, Sharing and stops).
  String? _shareId;
  ShareWriter? _shares;
  final _pacer = SharePacer();
  GeoPoint? _here;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _startedAt = DateTime.now();
    final config = await FlutterForegroundTask.getData<String>(key: configKey);
    _config = RideConfig.fromJson(_decode(config));
    final ride = await _savedRide();
    _l = lookupAppLocalizations(Locale(ride?.language ?? _config.language));
    if (ride != null) {
      _guide(ride);
    } else {
      if (kDebugMode) debugPrint('ride: watching');
      await FlutterForegroundTask.updateService(
        notificationTitle: _l!.checkingRide,
        notificationText: '',
        notificationButtons: [NotificationButton(id: endButton, text: _l!.end)],
      );
    }
    _follow();
  }

  Future<GuideRide?> _savedRide() async {
    final saved = await FlutterForegroundTask.getData<String>(key: rideKey);
    return GuideRide.fromJson(_decode(saved));
  }

  /// Guides to [ride] from here on; the ride is a bus.
  void _guide(GuideRide ride) {
    _ride = ride;
    _engine = GuideEngine(ride);
    _ready = false;
    if (ride.route case final route?) _tag = route;
    _verdict = RideVerdict.bus;
    _asking = false;
    if (kDebugMode) debugPrint('guide: started to ${ride.title}');
    if (ride.share && _shareId == null) unawaited(_startShare(newShareId()));
  }

  void _follow() {
    _interval = _engine == null
        ? const Duration(seconds: 10)
        : const Duration(seconds: 5);
    _fixes = Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        intervalDuration: _interval,
      ),
    ).listen(_onFix, onError: (Object _) => _lost(), onDone: _lost);
  }

  /// Location went off or away: the next beat follows again.
  void _lost() {
    unawaited(_fixes?.cancel());
    _fixes = null;
  }

  /// A guide began in a watched ride: fixes come faster.
  void _followFaster() {
    if (_interval == const Duration(seconds: 5)) return;
    _lost();
    _follow();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_fixes == null) _follow();
    if (_engine == null) unawaited(_checkOver());
  }

  /// A watched ride is over a little after the vehicle is left: once
  /// Android says so and neither that nor the vehicle part's last move is
  /// recent (walking on from the stop doesn't keep it going), or once
  /// nothing at all has moved for a long while.
  Future<void> _checkOver() async {
    final exit = int.tryParse(
      await FlutterForegroundTask.getData<String>(key: vehicleExitKey) ?? '',
    );
    final now = DateTime.now();
    final moved = _logic.movedAt ?? _logic.startedAt ?? _startedAt;
    final still = now.difference(moved);
    var off = false;
    if (exit != null && exit > _startedAt.millisecondsSinceEpoch) {
      final left = DateTime.fromMillisecondsSinceEpoch(exit);
      final vehicle = _logic.vehicleAt ?? moved;
      final since = left.isAfter(vehicle) ? left : vehicle;
      off = now.difference(since) >= _offAfter;
    }
    if (off || still >= _stillAfter) {
      await FlutterForegroundTask.stopService();
    }
  }

  Future<void> _onFix(Position position) async {
    final fix = RideFix(
      GeoPoint(position.latitude, position.longitude),
      position.timestamp,
      accuracy: position.accuracy,
    );
    _logic.add(fix);
    _here = fix.point;
    final engine = _engine;
    if (engine == null) {
      if (kDebugMode) {
        debugPrint(
          'ride: ${_logic.distance.round()} m, score ${_logic.score.toStringAsFixed(2)}',
        );
      }
      _shareFix(fix.point);
      if (_verdict == null && !_asking && _logic.ask) await _askOnABus();
      return;
    }
    final ride = _ride;
    final l = _l;
    final step = engine.update(fix);
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
    _shareFix(fix.point);
    switch (step.alert) {
      case StageDue(:final index):
        _ready = index < ride.stages.length - 1;
        await _buzz(ride.stages[index].pattern.buzz.repeated(2));
      case StopPassed():
        await _buzz(passedBuzz);
      case Arrived():
        _arrived = true;
        await _buzz(arrivedBuzz);
        await FlutterForegroundTask.stopService();
        return;
      case StillGoing():
        await _buzz(AlertPattern.gentleDoubleTap.buzz.repeated(2));
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

  /// "On a bus?", on the ride's own notification (no second one), with a
  /// gentle buzz: the rider's first two places, Yes when there are fewer,
  /// and Not a bus (Android shows three buttons at most). Hopin's card asks
  /// the same when it's open.
  Future<void> _askOnABus() async {
    final l = _l!;
    _asking = true;
    final places = _config.places.take(RideConfig.buttons).toList();
    await _buzz(AlertPattern.gentleDoubleTap.buzz);
    await FlutterForegroundTask.updateService(
      notificationTitle: l.onABus,
      notificationText: '',
      notificationButtons: [
        for (final (i, place) in places.indexed)
          NotificationButton(id: placeButton(i), text: place.name),
        if (places.length < RideConfig.buttons)
          NotificationButton(id: yesButton, text: l.yes),
        NotificationButton(id: notBusButton, text: l.notABus),
      ],
    );
    FlutterForegroundTask.sendDataToMain({'type': 'asking'});
  }

  /// An answer to "On a bus?", from the notification or the app.
  Future<void> _answer(String id) async {
    if (!_asking) return;
    final l = _l!;
    _asking = false;
    FlutterForegroundTask.sendDataToMain({'type': 'answered'});
    if (id == notBusButton) {
      _verdict = RideVerdict.notBus;
      await FlutterForegroundTask.stopService();
      return;
    }
    _verdict = RideVerdict.bus;
    final index = id.startsWith('place') ? int.tryParse(id.substring(5)) : null;
    if (index != null && index < _config.places.length) {
      final ride = _config.guideTo(_config.places[index]);
      await FlutterForegroundTask.saveData(
        key: rideKey,
        value: jsonEncode(ride.toJson()),
      );
      _guide(ride);
      _followFaster();
      FlutterForegroundTask.sendDataToMain({
        'type': 'guiding',
        'ride': ride.toJson(),
      });
      await _showGuideStart(ride);
      return;
    }
    await FlutterForegroundTask.updateService(
      notificationTitle: l.busRide,
      notificationText: '',
      notificationButtons: [NotificationButton(id: endButton, text: l.end)],
    );
    FlutterForegroundTask.sendDataToMain(_ridingMessage());
  }

  /// A bus ride with no guide: Home shows its slim bar.
  Map<String, Object?> _ridingMessage() => {
    'type': 'riding',
    'since': (_logic.startedAt ?? _startedAt).microsecondsSinceEpoch,
  };

  /// Shares the ride under [id] (the app's Share, or a guide to a place
  /// shared by itself); one share at a time.
  Future<void> _startShare(String id) async {
    if (_shareId != null) {
      FlutterForegroundTask.sendDataToMain(_sharingMessage());
      return;
    }
    final shares = await _writer();
    final uid = shares == null ? null : FirebaseAuth.instance.currentUser?.uid;
    if (shares == null || uid == null || _shareId != null) return;
    _shareId = id;
    final here = _here;
    // Not awaited: offline, Firestore keeps the write until it can send it,
    // and the ride never waits on the network.
    unawaited(
      shares
          .open(
            id,
            uid: uid,
            startedAt: _logic.startedAt ?? _startedAt,
            at: here,
            goal: _goal(),
          )
          .catchError(_shareFailed),
    );
    if (here != null) _pacer.sent(here, DateTime.now());
    if (kDebugMode) debugPrint('share: started');
    FlutterForegroundTask.sendDataToMain(_sharingMessage());
  }

  void _shareFix(GeoPoint here) {
    final id = _shareId;
    final shares = _shares;
    final now = DateTime.now();
    if (id == null || shares == null || !_pacer.due(here, now)) return;
    _pacer.sent(here, now);
    unawaited(
      shares.move(id, at: here, goal: _goal()).catchError(_shareFailed),
    );
  }

  /// Ends the share: it is deleted, and the link says the ride ended.
  Future<void> _endShare() async {
    final id = _shareId;
    final shares = _shares;
    if (id == null || shares == null) return;
    _shareId = null;
    if (kDebugMode) debugPrint('share: ended');
    FlutterForegroundTask.sendDataToMain(_sharingMessage());
    // Queued at once; waited for a moment only, as the service may be going.
    await shares
        .close(id)
        .timeout(const Duration(seconds: 3))
        .catchError(_shareFailed);
  }

  void _shareFailed(Object error) {
    if (kDebugMode) debugPrint('share: $error');
  }

  Map<String, Object?> _sharingMessage() => {'type': 'sharing', 'id': _shareId};

  Map<String, Object?> _taggedMessage() => {
    'type': 'tagged',
    'tag': _tag?.toJson(),
  };

  /// Where a guided ride is going, for its share.
  ShareGoal? _goal() {
    final ride = _ride;
    if (ride == null) return null;
    final status = _status;
    final left = status?.left;
    return ShareGoal(
      name: ride.title,
      nameTa: ride.names.ta,
      point: ride.to,
      minutesLeft: left == null ? null : wholeMinutes(left),
      metresLeft: status?.metres.round(),
    );
  }

  /// Firebase in the service's own isolate, started the first time a ride
  /// is shared.
  Future<ShareWriter?> _writer() async {
    if (_shares case final shares?) return shares;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: HopinFirebase.android);
      }
      return _shares = FirestoreShares();
    } on Object catch (error) {
      if (kDebugMode) debugPrint('share: no Firebase ($error)');
      return null;
    }
  }

  /// The app started a guide during a watched ride.
  Future<void> _guideFromApp() async {
    final ride = await _savedRide();
    if (ride == null) return;
    _asking = false;
    _guide(ride);
    _followFaster();
    await _showGuideStart(ride);
  }

  /// A guide that just began: its notification until the first fix.
  Future<void> _showGuideStart(GuideRide ride) async {
    _shown = null;
    await FlutterForegroundTask.updateService(
      notificationTitle: ride.title,
      notificationText: _l!.findingYou,
      notificationButtons: [NotificationButton(id: endButton, text: _l!.end)],
    );
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

  /// The ride's one notification during a guide, updated when its words
  /// change: where it's going and how long, "Get ready", "Get off next",
  /// "Passed your stop" or "Still going?" (with Keep), the stage's buzz
  /// having played.
  Future<void> _show(GuideStatus status) async {
    final l = _l!;
    final to = _to(status);
    final left = status.left;
    final (title, text) = switch (status.phase) {
      _ when status.asking => (l.stillGoing(_ride!.title), to),
      GuidePhase.riding when _ready => (l.getReady, to),
      GuidePhase.riding => (
        to,
        left == null ? '' : l.timeLeft(wholeMinutes(left)),
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
    if (data == askStatus) {
      if (status != null) {
        FlutterForegroundTask.sendDataToMain(statusMessage(status));
      }
      if (_asking) {
        FlutterForegroundTask.sendDataToMain({'type': 'asking'});
      }
      if (_engine == null && _verdict == RideVerdict.bus) {
        FlutterForegroundTask.sendDataToMain(_ridingMessage());
      }
      if (_shareId != null) {
        FlutterForegroundTask.sendDataToMain(_sharingMessage());
      }
      if (_tag != null) FlutterForegroundTask.sendDataToMain(_taggedMessage());
    } else if (data case {tagCommand: final Object? tag}) {
      _tag = RouteTag.fromJson(tag);
      FlutterForegroundTask.sendDataToMain(_taggedMessage());
    } else if (data case {shareCommand: final String id}) {
      unawaited(_startShare(id));
    } else if (data == stopShareCommand) {
      unawaited(_endShare());
    } else if (data == keepButton) {
      unawaited(_keepGoing());
    } else if (data == guideNow) {
      unawaited(_guideFromApp());
    } else if (data is String) {
      unawaited(_answer(data));
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == endButton) {
      unawaited(FlutterForegroundTask.stopService());
    } else if (id == keepButton) {
      unawaited(_keepGoing());
    } else {
      unawaited(_answer(id));
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    if (kDebugMode) debugPrint('guide: ended, arrived: $_arrived');
    _lost();
    await FlutterForegroundTask.saveData(
      key: quietKey,
      value: '${DateTime.now().millisecondsSinceEpoch}',
    );
    await _endShare();
    // Ending stops a buzz still playing; arriving lets its tap finish.
    if (!_arrived) await Vibration.cancel();
    await FlutterForegroundTask.removeData(key: rideKey);
    await _keepRide();
    FlutterForegroundTask.sendDataToMain(
      endedMessage(arrived: _arrived, gaveUp: _gaveUp),
    );
  }

  /// Hands the finished ride to the app: kept until the app has it.
  Future<void> _keepRide() async {
    final verdict = _verdict ?? RideVerdict.unknown;
    // Its vehicle part: a walk that set it off is no ride.
    final ride = _logic.ride;
    final short = ride.length < _keepAfter || ride.distance < _keepAfterMetres;
    if (short && verdict != RideVerdict.notBus) return;
    if (_logic.startedAt == null) return;
    final record = RideRecord.fromLogic(
      _logic,
      id: _rideId,
      verdict: verdict,
      endedAt: _logic.lastAt ?? DateTime.now(),
      guideTo: _ride?.title,
      route: _tag,
    ).toJson();
    await FlutterForegroundTask.saveData(
      key: '$pendingRidePrefix$_rideId',
      value: jsonEncode(record),
    );
    FlutterForegroundTask.sendDataToMain({'type': 'ride', 'ride': record});
  }
}

Object? _decode(String? json) {
  if (json == null) return null;
  try {
    return jsonDecode(json);
  } on FormatException {
    return null;
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
