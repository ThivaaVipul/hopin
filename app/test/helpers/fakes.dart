import 'dart:async';

import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/profile/profile_repository.dart';

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
