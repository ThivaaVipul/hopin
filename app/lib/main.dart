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
import 'package:hopin/features/home/widgets/hopin_map.dart';
import 'package:hopin/firebase_options.dart';

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
      mapBuilder: boardMap,
      guide: ForegroundGuideService(),
    ),
  );
}
