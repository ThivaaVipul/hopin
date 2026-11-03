import 'package:flutter_test/flutter_test.dart';
import 'package:hopin/app/router.dart';
import 'package:hopin/app/session/session_cubit.dart';

void main() {
  test('waits on the start screen until the session is known', () {
    expect(sessionRedirect(SessionStatus.unknown, Routes.home), Routes.start);
    expect(sessionRedirect(SessionStatus.unknown, Routes.start), isNull);
  });

  test('sends signed-out people to sign-in', () {
    expect(
      sessionRedirect(SessionStatus.signedOut, Routes.start),
      Routes.signIn,
    );
    expect(
      sessionRedirect(SessionStatus.signedOut, Routes.home),
      Routes.signIn,
    );
    expect(sessionRedirect(SessionStatus.signedOut, Routes.signIn), isNull);
  });

  test('sends signed-in people home and leaves them where they are', () {
    expect(sessionRedirect(SessionStatus.signedIn, Routes.start), Routes.home);
    expect(sessionRedirect(SessionStatus.signedIn, Routes.signIn), Routes.home);
    expect(sessionRedirect(SessionStatus.signedIn, Routes.home), isNull);
  });
}
