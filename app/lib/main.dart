import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hopin/app/app.dart';
import 'package:hopin/core/auth/firebase_auth_repository.dart';
import 'package:hopin/core/profile/profile_repository.dart';
import 'package:hopin/firebase_options.dart';

Future<void> main() async {
  if (HopinFirebase.apiKey.isEmpty) {
    throw StateError(
      'Build with --dart-define-from-file=firebase.local.json '
      '(the Firebase API key is not in the repo; CLAUDE.md, Commands).',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: HopinFirebase.android);
  runApp(
    HopinApp(auth: FirebaseAuthRepository(), profiles: FirestoreProfiles()),
  );
}
