// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hopin';

  @override
  String get tagline => 'Never miss your stop.';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get signInFailed =>
      'Sign-in didn\'t work. Check your internet and try again.';

  @override
  String hello(String name) {
    return 'Hi, $name';
  }

  @override
  String get riderOn => 'Rider access is on';

  @override
  String get riderWaiting => 'Waiting for rider access';

  @override
  String get checkAgain => 'Check again';

  @override
  String get mapNext => 'The map arrives in the next update.';

  @override
  String get signOut => 'Sign out';
}
