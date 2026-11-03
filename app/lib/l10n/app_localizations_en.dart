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
  String get signOut => 'Sign out';

  @override
  String get whereTo => 'Where to?';

  @override
  String get add => 'Add';

  @override
  String get kindHome => 'Home';

  @override
  String get kindWork => 'Work';

  @override
  String get kindUni => 'Uni';

  @override
  String get kindOther => 'Other';

  @override
  String get locationWhy =>
      'Hopin uses your location to show where you are and to buzz before your stop.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get turnOnLocation => 'Turn on location';

  @override
  String get showMe => 'Show where I am';

  @override
  String get account => 'Account';

  @override
  String awayKm(String km) {
    return '$km km away';
  }

  @override
  String awayM(String m) {
    return '$m m away';
  }

  @override
  String get droppedPin => 'Dropped pin';

  @override
  String get save => 'Save';

  @override
  String get edit => 'Edit';

  @override
  String get close => 'Close';

  @override
  String get savePlace => 'Save place';

  @override
  String get editPlace => 'Edit place';

  @override
  String get placeName => 'Name';

  @override
  String get delete => 'Delete';

  @override
  String get recent => 'Recent';

  @override
  String get search => 'Search';

  @override
  String get back => 'Back';

  @override
  String get searchFailed =>
      'Search didn\'t work. Check your internet and try again.';

  @override
  String get nothingFound => 'Nothing found. Try another name.';
}
