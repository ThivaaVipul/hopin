import 'dart:async';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
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
    bool deleted = false,
  }) async {
    if (offline) throw StateError('offline');
    puts.add((path, data, deleted));
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

HopinDatabase memoryDatabase([String _ = '']) {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return HopinDatabase(NativeDatabase.memory());
}

/// Nominatim answering from [respond], with no waiting between requests.
Nominatim fakeNominatim(
  Future<http.Response> Function(http.Request request) respond,
) => Nominatim(client: MockClient(respond), wait: (_) async {});
