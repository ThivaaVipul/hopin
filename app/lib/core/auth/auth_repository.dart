import 'package:equatable/equatable.dart';

/// The signed-in person, and whether they are a rider yet.
class Account extends Equatable {
  const Account({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.isRider,
  });

  final String uid;

  /// As Google gives it; may be empty.
  final String name;
  final String? photoUrl;

  /// True once the project owner has set the `rider` claim on this account
  /// (docs/ARCHITECTURE.md, Access). Until then nothing syncs.
  final bool isRider;

  String get firstName {
    final first = name.trim().split(RegExp(r'\s+')).first;
    return first;
  }

  @override
  List<Object?> get props => [uid, name, photoUrl, isRider];
}

enum SignInOutcome { signedIn, cancelled }

/// Google sign-in and the rider claim. The app reaches Firebase Auth only
/// through this, so screens and tests never touch Firebase directly.
abstract interface class AuthRepository {
  /// The current account on every sign-in, sign-out and token refresh (a
  /// refresh is how a newly set rider claim arrives); null when signed out.
  Stream<Account?> get accountChanges;

  Future<SignInOutcome> signIn();

  Future<void> signOut();

  /// Asks for a fresh token, so a rider claim set since sign-in shows up.
  Future<void> refresh();
}
