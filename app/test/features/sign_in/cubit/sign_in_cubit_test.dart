import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/core/auth/auth_repository.dart';
import 'package:hopin/features/sign_in/cubit/sign_in_cubit.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAuth auth;

  setUp(() => auth = FakeAuth());

  blocTest<SignInCubit, SignInStatus>(
    'signs in and goes back to idle',
    build: () => SignInCubit(auth),
    act: (cubit) => cubit.signIn(),
    expect: () => [SignInStatus.busy, SignInStatus.idle],
    verify: (_) => expect(auth.signIns, 1),
  );

  blocTest<SignInCubit, SignInStatus>(
    'treats a closed Google sheet as no failure',
    build: () {
      auth.nextOutcome = SignInOutcome.cancelled;
      return SignInCubit(auth);
    },
    act: (cubit) => cubit.signIn(),
    expect: () => [SignInStatus.busy, SignInStatus.idle],
  );

  blocTest<SignInCubit, SignInStatus>(
    'shows a failure and reports it',
    build: () {
      auth.nextError = StateError('network');
      return SignInCubit(auth);
    },
    act: (cubit) => cubit.signIn(),
    expect: () => [SignInStatus.busy, SignInStatus.failed],
    errors: () => [isA<StateError>()],
  );

  blocTest<SignInCubit, SignInStatus>(
    'ignores a second tap while busy',
    build: () => SignInCubit(auth),
    act: (cubit) => Future.wait([cubit.signIn(), cubit.signIn()]),
    verify: (_) => expect(auth.signIns, 1),
  );
}
