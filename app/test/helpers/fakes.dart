import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/guide/guide_service.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_config.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/features/rides/widgets/ride_map.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const newcomer = Account(uid: 'r1', name: 'Rider One', isRider: false);
const rider = Account(uid: 'r1', name: 'Rider One', isRider: true);

/// Sign-in without Google or Firebase. [emit] stands in for Firebase telling
/// the app who is signed in; events arrive synchronously.
class FakeAuth implements AuthRepository {
  final _changes = StreamController<Account?>.broadcast(sync: true);
  SignInOutcome nextOutcome = SignInOutcome.signedIn;
  Object? nextError;
  int signIns = 0;
  int signOuts = 0;
  int refreshes = 0;

  void emit(Account? account) => _changes.add(account);

  @override
  Stream<Account?> get accountChanges => _changes.stream;

  @override
  Future<SignInOutcome> signIn() async {
    signIns++;
    final error = nextError;
    if (error != null) throw error;
    return nextOutcome;
  }

  @override
  Future<void> signOut() async {
    signOuts++;
    _changes.add(null);
  }

  @override
  Future<void> refresh() async => refreshes++;
}

class FakeProfiles implements ProfileRepository {
  final saved = <(String, String)>[];
  Object? nextError;

  @override
  Future<void> save(Account account, {required String language}) async {
    final error = nextError;
    if (error != null) {
      nextError = null;
      throw error;
    }
    saved.add((account.uid, language));
  }
}

/// Firestore in memory: [put] records writes and stamps a server time; [push]
/// delivers documents to listeners as if they came from the server.
class FakeRemote implements Remote {
  final puts = <(String, Map<String, Object?>, bool)>[];
  final _listeners = <String, StreamController<List<RemoteDoc>>>{};
  final queried = <(String, int)>[];
  bool offline = false;

  /// While set, uploads wait for it; [waiting] counts the ones held.
  Completer<void>? hold;
  int waiting = 0;

  @override
  Stream<List<RemoteDoc>> changes(String collection, int after) {
    queried.add((collection, after));
    return (_listeners[collection] ??=
            StreamController<List<RemoteDoc>>.broadcast(sync: true))
        .stream;
  }

  void push(String collection, List<RemoteDoc> docs) =>
      _listeners[collection]?.add(docs);

  @override
  Future<void> put(
    String path,
    Map<String, Object?> data, {
    bool? deleted,
  }) async {
    if (offline) throw StateError('offline');
    final hold = this.hold;
    if (hold != null) {
      waiting++;
      await hold.future;
    }
    puts.add((path, data, deleted ?? false));
  }
}

/// A phone's location without GPS.
class FakeLocation implements LocationService {
  FakeLocation({
    this.access = LocationAccess.denied,
    this.afterRequest = LocationAccess.granted,
    this.here,
  });

  LocationAccess access;
  LocationAccess afterRequest;
  GeoPoint? here;
  int requests = 0;
  final _positions = StreamController<GeoPoint>.broadcast(sync: true);

  void move(GeoPoint point) {
    here = point;
    _positions.add(point);
  }

  @override
  Future<LocationAccess> check() async => access;

  @override
  Future<LocationAccess> request() async {
    requests++;
    return access = afterRequest;
  }

  @override
  Future<GeoPoint?> current() async => here;

  @override
  Stream<GeoPoint> positions() => _positions.stream;
}

/// The map without MapLibre's native view: it shows what it was asked to draw.
Widget fakeMap(MapProps props) => ColoredBox(
  key: const ValueKey('map'),
  color: const Color(0xFFECEFEA),
  child: Align(
    alignment: Alignment.center,
    child: Text(
      'map: ${props.places.length} places',
      textDirection: TextDirection.ltr,
    ),
  ),
);

/// A ride's map without MapLibre: it says how much it was asked to draw.
Widget fakeRideMap(RideMapProps props) => ColoredBox(
  key: const ValueKey('ride map'),
  color: const Color(0xFFECEFEA),
  child: Align(
    alignment: Alignment.center,
    child: Text(
      'ride map: ${props.path.length} points, ${props.halts.length} halts',
      textDirection: TextDirection.ltr,
    ),
  ),
);

HopinDatabase memoryDatabase([String _ = '']) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return HopinDatabase(NativeDatabase.memory());
}

/// Nominatim answering from [respond], with no waiting between requests.
Nominatim fakeNominatim(
  Future<http.Response> Function(http.Request request) respond,
) => Nominatim(client: MockClient(respond), wait: (_) async {});

/// The ride service without Android. [emit] stands in for its news; events
/// arrive synchronously.
class FakeGuide implements GuideService {
  FakeGuide({this.ride, this.phoneMaker = PhoneMaker.xiaomi});

  /// The running guide.
  GuideRide? ride;
  PhoneMaker phoneMaker;
  bool startWorks = true;
  bool notifications = false;
  bool allowOnAsk = true;
  final started = <GuideRide>[];
  int ends = 0;
  int notificationAsks = 0;
  int backgroundAsks = 0;
  int settingsOpened = 0;
  int keeps = 0;
  int appSettingsOpened = 0;
  bool background = false;
  final played = <Buzz>[];
  final answers = <String>[];
  final configs = <RideConfig>[];
  final pending = <RideRecord>[];
  final forgotten = <String>[];
  var detected = const Detection();
  var detectionAfterTurnOn = const Detection(
    on: true,
    activity: true,
    allTheTime: true,
  );
  int detectNows = 0;
  final _events = StreamController<GuideEvent>.broadcast(sync: true);

  void emit(GuideEvent event) => _events.add(event);

  @override
  Stream<GuideEvent> get events => _events.stream;

  @override
  Future<GuideRide?> running() async => ride;

  @override
  Future<bool> start(GuideRide ride) async {
    started.add(ride);
    if (!startWorks) return false;
    this.ride = ride;
    return true;
  }

  @override
  Future<void> end() async {
    ends++;
    ride = null;
  }

  @override
  Future<bool> notificationsAllowed() async => notifications;

  @override
  Future<bool> askForNotifications() async {
    notificationAsks++;
    return notifications = allowOnAsk;
  }

  @override
  Future<void> askToRunInBackground() async => backgroundAsks++;

  @override
  Future<PhoneMaker> maker() async => phoneMaker;

  @override
  Future<void> openMakerSettings() async => settingsOpened++;

  @override
  Future<void> keepGoing() async => keeps++;

  @override
  Future<bool> runsInBackground() async => background;

  @override
  Future<void> openAppSettings() async => appSettingsOpened++;

  @override
  Future<void> play(Buzz buzz) async => played.add(buzz);

  @override
  Future<void> answer(String button) async => answers.add(button);

  @override
  Future<void> saveRideConfig(RideConfig config) async => configs.add(config);

  @override
  Future<List<RideRecord>> pendingRides() async => [...pending];

  @override
  Future<void> forgetPendingRide(String id) async {
    forgotten.add(id);
    pending.removeWhere((ride) => ride.id == id);
  }

  @override
  Future<Detection> detection() async => detected;

  @override
  Future<Detection> turnOnDetection(String language) async =>
      detected = detectionAfterTurnOn;

  @override
  Future<void> turnOffDetection() async =>
      detected = const Detection(activity: true, allTheTime: true);

  @override
  Future<void> detectNow() async => detectNows++;
}

/// GitHub Releases without the network: [release] is what's out.
class FakeUpdates implements UpdateService {
  FakeUpdates({this.installed = 0, this.release});

  @override
  int installed;
  Release? release;
  bool offline = false;
  bool downloadFails = false;
  bool mayInstall = true;
  int checks = 0;
  int downloads = 0;
  final installs = <String>[];

  @override
  Future<Release?> latest() async {
    checks++;
    if (offline) throw const SocketException('offline');
    return release;
  }

  @override
  Future<String> download(
    Release release,
    void Function(double) progress,
  ) async {
    downloads++;
    if (downloadFails) throw const SocketException('dropped');
    progress(0.5);
    progress(1);
    return 'updates/hopin-${release.version}.apk';
  }

  @override
  Future<bool> install(String file) async {
    installs.add(file);
    return mayInstall;
  }
}
