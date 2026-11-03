import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/session/session_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeAuth auth;
  late FakeProfiles profiles;

  setUp(() {
    auth = FakeAuth();
    profiles = FakeProfiles();
  });

  test('starts unknown', () {
    expect(SessionCubit(auth, profiles).state, const SessionState.unknown());
  });

  blocTest<SessionCubit, SessionState>(
    'follows sign-in, the rider claim arriving, and sign-out',
    build: () => SessionCubit(auth, profiles),
    act: (cubit) {
      auth
        ..emit(null)
        ..emit(newcomer)
        ..emit(rider)
        ..emit(null);
    },
    expect: () => const [
      SessionState.signedOut(),
      SessionState.signedIn(newcomer),
      SessionState.signedIn(rider),
      SessionState.signedOut(),
    ],
  );

  blocTest<SessionCubit, SessionState>(
    'saves the profile only once the account is a rider, once per session',
    build: () => SessionCubit(auth, profiles, language: 'ta'),
    act: (cubit) {
      auth
        ..emit(newcomer)
        ..emit(rider)
        ..emit(rider)
        ..emit(null)
        ..emit(rider);
    },
    verify: (_) => expect(profiles.saved, [('r1', 'ta'), ('r1', 'ta')]),
  );

  blocTest<SessionCubit, SessionState>(
    'reports a failed profile save and tries again on the next change',
    build: () {
      profiles.nextError = StateError('offline');
      return SessionCubit(auth, profiles);
    },
    act: (cubit) async {
      auth.emit(rider);
      await Future<void>.delayed(Duration.zero);
      auth
        ..emit(null)
        ..emit(rider);
    },
    errors: () => [isA<StateError>()],
    verify: (_) => expect(profiles.saved, [('r1', 'en')]),
  );

  test('refresh and sign-out go to the auth repository', () async {
    final cubit = SessionCubit(auth, profiles);
    await cubit.refresh();
    await cubit.signOut();
    expect(auth.refreshes, 1);
    expect(auth.signOuts, 1);
    await cubit.close();
  });
}
