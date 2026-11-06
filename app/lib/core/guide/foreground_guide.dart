import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/guide/ride_task.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_config.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';
import 'package:hopin/l10n/app_localizations.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibration/vibration.dart';

/// The guide as a foreground service of type location (flutter_foreground_task),
/// started while the app is open, so "while using the app" location covers it
/// after the app closes. It never restarts by itself: Android would not let a
/// service started in the background use that location (docs/ARCHITECTURE.md,
/// Get-off guide).
class ForegroundGuideService implements GuideService {
  ForegroundGuideService() {
    FlutterForegroundTask.addTaskDataCallback(_onMessage);
  }

  /// Call once in main(), before the app runs.
  static void prepare() => FlutterForegroundTask.initCommunicationPort();

  static const _phone = MethodChannel('app.hopin/phone');
  final _events = StreamController<GuideEvent>.broadcast();

  void _onMessage(Object message) {
    if (message is! Map) return;
    switch (message['type']) {
      case 'status':
        if (GuideStatus.fromJson(message['status']) case final status?) {
          _events.add(GuideUpdate(status));
        }
      case 'asking':
        _events.add(const RideQuestion());
      case 'answered':
        _events.add(const RideAnswered());
      case 'guiding':
        if (GuideRide.fromJson(message['ride']) case final ride?) {
          _events.add(GuideStarted(ride));
        }
      case 'ride':
        if (RideRecord.fromJson(message['ride']) case final ride?) {
          _events.add(RideLogged(ride));
        }
      case 'sharing':
        final id = message['id'];
        _events.add(ShareChanged(id is String ? id : null));
      case 'tagged':
        _events.add(RideTagged(RouteTag.fromJson(message['tag'])));
      case 'riding':
        if (message['since'] case final int since) {
          _events.add(RideNoticed(DateTime.fromMicrosecondsSinceEpoch(since)));
        }
      case 'ended':
        _events.add(
          GuideEnded(
            arrived: message['arrived'] == true,
            gaveUp: message['gaveUp'] == true,
          ),
        );
    }
  }

  @override
  Stream<GuideEvent> get events => _events.stream;

  @override
  Future<bool> serviceRunning() => FlutterForegroundTask.isRunningService;

  @override
  Future<GuideRide?> running() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.removeData(key: rideKey);
      return null;
    }
    final saved = await FlutterForegroundTask.getData<String>(key: rideKey);
    final ride = saved == null ? null : GuideRide.fromJson(jsonDecode(saved));
    // Also while only watching: an open "On a bus?" comes back as a card.
    FlutterForegroundTask.sendDataToTask(askStatus);
    return ride;
  }

  static AndroidNotificationOptions _notification(AppLocalizations l) =>
      AndroidNotificationOptions(
        channelId: 'guide',
        channelName: l.channelGuide,
        onlyAlertOnce: true,
      );

  static final _task = ForegroundTaskOptions(
    // A beat to follow GPS again if location went away, and to see whether
    // a watched ride is over.
    eventAction: ForegroundTaskEventAction.repeat(30000),
    allowAutoRestart: false,
    stopWithTask: false,
  );

  static const _icon = NotificationIcon(
    metaDataName: 'app.hopin.NOTIFICATION_ICON',
    backgroundColor: Color(0xFFFFB020),
  );

  @override
  Future<bool> start(GuideRide ride) async {
    final l = lookupAppLocalizations(Locale(ride.language));
    final running = await FlutterForegroundTask.isRunningService;
    final guiding =
        running &&
        await FlutterForegroundTask.getData<String>(key: rideKey) != null;
    await FlutterForegroundTask.saveData(
      key: rideKey,
      value: jsonEncode(ride.toJson()),
    );
    if (running && !guiding) {
      // A watched ride: the service guides from here, keeping the ride.
      FlutterForegroundTask.sendDataToTask(guideNow);
      return true;
    }
    if (running) await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.saveData(
      key: rideKey,
      value: jsonEncode(ride.toJson()),
    );
    FlutterForegroundTask.init(
      androidNotificationOptions: _notification(l),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: _task,
    );
    final result = await FlutterForegroundTask.startService(
      serviceId: 300,
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: ride.title,
      notificationText: l.findingYou,
      notificationIcon: _icon,
      notificationButtons: [NotificationButton(id: endButton, text: l.end)],
      callback: startRideTask,
    );
    if (result is ServiceRequestSuccess) return true;
    await FlutterForegroundTask.removeData(key: rideKey);
    return false;
  }

  @override
  Future<void> end() async {
    await FlutterForegroundTask.stopService();
    await FlutterForegroundTask.removeData(key: rideKey);
  }

  @override
  Future<void> answer(String button) async =>
      FlutterForegroundTask.sendDataToTask(button);

  @override
  Future<void> saveRideConfig(RideConfig config) async {
    await FlutterForegroundTask.saveData(
      key: configKey,
      value: jsonEncode(config.toJson()),
    );
  }

  @override
  Future<List<RideRecord>> pendingRides() async => [
    for (final MapEntry(:key, :value)
        in (await FlutterForegroundTask.getAllData()).entries)
      if (key.startsWith(pendingRidePrefix) && value is String)
        ?RideRecord.fromJson(_json(value)),
  ];

  static Object? _json(String text) {
    try {
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> forgetPendingRide(String id) async {
    await FlutterForegroundTask.removeData(key: '$pendingRidePrefix$id');
  }

  @override
  Future<Detection> detection() async {
    final activity = await Permission.activityRecognition.isGranted;
    final always = await Permission.locationAlways.isGranted;
    final on = await _phone.invokeMethod<bool>('detectionEnabled') ?? false;
    return Detection(
      on: on && activity && always,
      activity: activity,
      allTheTime: always,
    );
  }

  @override
  Future<Detection> turnOnDetection(String language) async {
    if (!await Permission.activityRecognition.request().isGranted) {
      return detection();
    }
    if (!await Permission.locationAlways.request().isGranted) {
      return detection();
    }
    final l = lookupAppLocalizations(Locale(language));
    // flutter_foreground_task's own start options (its startService builds
    // the same), for the native receiver to start the service with.
    await _phone.invokeMethod<bool>('enableDetection', {
      'serviceId': 300,
      'serviceTypes': [ForegroundServiceTypes.location.rawValue],
      ..._task.toJson(),
      'notificationContentTitle': l.checkingRide,
      'notificationContentText': '',
      'icon': _icon.toJson(),
      'buttons': <Object>[],
      'initialRoute': null,
      ..._notification(l).toJson(),
      'callbackHandle': PluginUtilities.getCallbackHandle(
        startRideTask,
      )?.toRawHandle(),
    });
    return detection();
  }

  @override
  Future<void> turnOffDetection() async {
    await _phone.invokeMethod<void>('disableDetection');
  }

  @override
  Future<void> detectNow() async {
    await _phone.invokeMethod<void>('detectNow');
  }

  @override
  Future<void> keepGoing() async =>
      FlutterForegroundTask.sendDataToTask(keepButton);

  @override
  Future<bool> runsInBackground() =>
      FlutterForegroundTask.isIgnoringBatteryOptimizations;

  @override
  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  @override
  Future<void> play(Buzz buzz) async {
    if (!await Vibration.hasVibrator()) return;
    await Vibration.vibrate(
      pattern: buzz.timings,
      intensities: buzz.amplitudes,
    );
  }

  @override
  Future<bool> notificationsAllowed() async =>
      await FlutterForegroundTask.checkNotificationPermission() ==
      NotificationPermission.granted;

  @override
  Future<bool> askForNotifications() async =>
      await FlutterForegroundTask.requestNotificationPermission() ==
      NotificationPermission.granted;

  @override
  Future<void> askToRunInBackground() async {
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) return;
    await FlutterForegroundTask.requestIgnoreBatteryOptimization();
  }

  @override
  Future<PhoneMaker> maker() async {
    final name = await _phone.invokeMethod<String>('maker') ?? '';
    return switch (name) {
      // Android names the maker, not the brand, for all of Xiaomi's phones.
      'xiaomi' => PhoneMaker.xiaomi,
      'samsung' => PhoneMaker.samsung,
      _ => PhoneMaker.other,
    };
  }

  @override
  Future<void> openMakerSettings() async {
    if (await maker() == PhoneMaker.xiaomi) {
      await _phone.invokeMethod<bool>('openAutostart');
    } else {
      await Geolocator.openAppSettings();
    }
  }

  @override
  Future<void> share(String id) async =>
      FlutterForegroundTask.sendDataToTask({shareCommand: id});

  @override
  Future<void> tag(RouteTag? tag) async =>
      FlutterForegroundTask.sendDataToTask({tagCommand: tag?.toJson()});

  @override
  Future<void> stopSharing() async =>
      FlutterForegroundTask.sendDataToTask(stopShareCommand);
}
