import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hopin/core/auth/auth_repository.dart';

enum SignInStatus { idle, busy, failed }

/// The sign-in button. A cancelled Google sheet is not a failure: the page
/// just waits again. Success needs no state here: the session moves on.
class SignInCubit extends Cubit<SignInStatus> {
  SignInCubit(this._auth) : super(SignInStatus.idle);

  final AuthRepository _auth;

  Future<void> signIn() async {
    if (state == SignInStatus.busy) return;
    emit(SignInStatus.busy);
    try {
      await _auth.signIn();
      emit(SignInStatus.idle);
    } catch (error, stack) {
      addError(error, stack);
      emit(SignInStatus.failed);
    }
  }
}
