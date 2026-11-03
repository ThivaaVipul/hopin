// Firebase options for the Android app, from the project's SDK config
// (`firebase apps:sdkconfig ANDROID`). The API key is not in the repo: builds
// take it from `--dart-define-from-file=firebase.local.json` (git-ignored) on
// this PC and from the FIREBASE_API_KEY secret in Actions. It still ships inside
// the APK, as every Firebase key does; it is restricted to this app, and access
// to data rests on the Firestore rules.
import 'package:firebase_core/firebase_core.dart';

class HopinFirebase {
  const HopinFirebase._();

  static const String apiKey = String.fromEnvironment('HOPIN_FIREBASE_API_KEY');

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: apiKey,
    appId: '1:254960190290:android:41d42f7b94c4e240ef708b',
    messagingSenderId: '254960190290',
    projectId: 'hopin-riders',
    storageBucket: 'hopin-riders.firebasestorage.app',
  );

  /// The project's web OAuth client: Google sign-in on Android asks for an ID
  /// token for this audience, which Firebase Auth accepts.
  static const String googleServerClientId =
      '254960190290-aire9rhmqe2kmr33914cb5sgsn03cm38.apps.googleusercontent.com';
}
