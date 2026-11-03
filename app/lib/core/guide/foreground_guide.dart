import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/guide/ride_task.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/l10n/app_localizations.dart';

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
      case 'ended':
        _events.add(GuideEnded(arrived: message['arrived'] == true));
    }
  }

  @override
  Stream<GuideEvent> get events => _events.stream;

  @override
  Future<GuideRide?> running() async {
    if (!await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.removeData(key: rideKey);
      return null;
    }
    final saved = await FlutterForegroundTask.getData<String>(key: rideKey);
    final ride = saved == null ? null : GuideRide.fromJson(jsonDecode(saved));
    if (ride != null) FlutterForegroundTask.sendDataToTask(askStatus);
    return ride;
  }

  @override
  Future<bool> start(GuideRide ride) async {
    final l = lookupAppLocalizations(Locale(ride.language));
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'guide',
        channelName: l.channelGuide,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        // A beat to follow GPS again if location went away.
        eventAction: ForegroundTaskEventAction.repeat(30000),
        allowAutoRestart: false,
        stopWithTask: false,
      ),
    );
    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.stopService();
    }
    await FlutterForegroundTask.saveData(
      key: rideKey,
      value: jsonEncode(ride.toJson()),
    );
    final result = await FlutterForegroundTask.startService(
      serviceId: 300,
      serviceTypes: [ForegroundServiceTypes.location],
      notificationTitle: ride.title,
      notificationText: l.findingYou,
      notificationIcon: const NotificationIcon(
        metaDataName: 'app.hopin.NOTIFICATION_ICON',
        backgroundColor: Color(0xFFFFB020),
      ),
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
}
