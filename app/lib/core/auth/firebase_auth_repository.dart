import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/firebase_options.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _ready;

  Future<void> _init() => _ready ??= _google.initialize(
    serverClientId: HopinFirebase.googleServerClientId,
  );

  @override
  Stream<Account?> get accountChanges =>
      _auth.idTokenChanges().asyncMap(_account);

  Future<Account?> _account(User? user) async {
    if (user == null) return null;
    final token = await user.getIdTokenResult();
    return Account(
      uid: user.uid,
      name: user.displayName ?? '',
      photoUrl: user.photoURL,
      isRider: token.claims?['rider'] == true,
    );
  }

  @override
  Future<SignInOutcome> signIn() async {
    await _init();
    final GoogleSignInAccount account;
    try {
      account = await _google.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return SignInOutcome.cancelled;
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    await _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
    return SignInOutcome.signedIn;
  }

  @override
  Future<void> signOut() async {
    await _init();
    await _google.signOut();
    await _auth.signOut();
  }

  @override
  Future<void> refresh() async {
    await _auth.currentUser?.getIdToken(true);
  }
}
