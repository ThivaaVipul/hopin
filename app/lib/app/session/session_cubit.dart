import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/core/profile/profile_repository.dart';

enum SessionStatus { unknown, signedOut, signedIn }

class SessionState extends Equatable {
  const SessionState._(this.status, this.account);

  const SessionState.unknown() : this._(SessionStatus.unknown, null);
  const SessionState.signedOut() : this._(SessionStatus.signedOut, null);
  const SessionState.signedIn(Account account)
    : this._(SessionStatus.signedIn, account);

  final SessionStatus status;
  final Account? account;

  @override
  List<Object?> get props => [status, account];
}

/// Who is signed in, for the whole app. Once the account is a rider, its
/// profile is written (once per session); the app works before that, and
/// syncing simply waits (docs/PLAN.md, Get-off guide).
class SessionCubit extends Cubit<SessionState> {
  SessionCubit(this._auth, this._profiles, {String Function()? language})
    : _language = language ?? _english,
      super(const SessionState.unknown()) {
    _subscription = _auth.accountChanges.listen(_onAccount, onError: addError);
  }

  final AuthRepository _auth;
  final ProfileRepository _profiles;
  final String Function() _language;

  static String _english() => 'en';
  late final StreamSubscription<Account?> _subscription;
  String? _profileSavedFor;

  void _onAccount(Account? account) {
    if (account == null) {
      _profileSavedFor = null;
      emit(const SessionState.signedOut());
      return;
    }
    emit(SessionState.signedIn(account));
    if (account.isRider && _profileSavedFor != account.uid) {
      _profileSavedFor = account.uid;
      unawaited(
        _profiles.save(account, language: _language()).catchError((
          Object error,
          StackTrace stack,
        ) {
          _profileSavedFor = null;
          addError(error, stack);
        }),
      );
    }
  }

  /// The app's language changed: the profile says so too.
  void languageChanged() {
    final account = state.account;
    if (account == null || !account.isRider) return;
    _profileSavedFor = null;
    _onAccount(account);
  }

  /// Looks again for the rider claim (the app calls this when it comes back
  /// to the front).
  Future<void> refresh() => _auth.refresh();

  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
