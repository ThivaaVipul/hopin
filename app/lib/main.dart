import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hopin/app/app.dart';
import 'package:hopin/core/auth/firebase_auth_repository.dart';
import 'package:hopin/core/data/local/database.dart';
import 'package:hopin/core/data/remote/remote.dart';
import 'package:hopin/core/guide/foreground_guide.dart';
import 'package:hopin/core/location/location_service.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/core/search/nominatim.dart';
import 'package:hopin/core/search/osrm.dart';
import 'package:hopin/core/search/overpass.dart';
import 'package:hopin/core/search/route_files.dart';
import 'package:hopin/core/share/shares.dart';
import 'package:hopin/core/update/updates.dart';
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/features/rides/widgets/ride_map.dart';
import 'package:hopin/features/routes/widgets/route_map.dart';
import 'package:hopin/firebase_options.dart';
import 'package:share_plus/share_plus.dart';

Future<void> main() async {
  if (HopinFirebase.apiKey.isEmpty) {
    throw StateError(
      'Build with --dart-define-from-file=firebase.local.json '
      '(the Firebase API key is not in the repo; CLAUDE.md, Commands).',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  prepareBoardMap();
  ForegroundGuideService.prepare();
  await Firebase.initializeApp(options: HopinFirebase.android);
  runApp(
    HopinApp(
      auth: FirebaseAuthRepository(),
      profiles: FirestoreProfiles(),
      remote: FirestoreRemote(),
      openDatabase: HopinDatabase.forAccount,
      location: GeolocatorLocation(),
      nominatim: Nominatim(),
      overpass: Overpass(),
      osrm: Osrm(),
      routeFiles: RouteFiles(),
      mapBuilder: boardMap,
      rideMapBuilder: boardRideMap,
      routeMapBuilder: boardRouteMap,
      guide: ForegroundGuideService(),
      shares: FirestoreShares(),
      shareSheet: (text) async =>
          SharePlus.instance.share(ShareParams(text: text)),
      updates: GitHubUpdates(),
    ),
  );
}
