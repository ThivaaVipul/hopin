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

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get getReady => 'Get ready';

  @override
  String get getOffNext => 'Get off next';

  @override
  String get passedStop => 'You passed your stop';

  @override
  String get arrived => 'You\'ve arrived';

  @override
  String distanceKm(String km) {
    return '$km km';
  }

  @override
  String distanceM(String m) {
    return '$m m';
  }

  @override
  String minutesLeft(int minutes) {
    return '$minutes min';
  }

  @override
  String distanceTo(String distance, String place) {
    return '$distance to $place';
  }

  @override
  String nowNear(String place) {
    return 'Now near $place';
  }

  @override
  String get findingYou => 'Finding you';

  @override
  String get notificationsWhy =>
      'Hopin shows the guide in your notifications and alerts you before your stop, even with the screen off.';

  @override
  String get keepRunning => 'Keep Hopin running';

  @override
  String get xiaomiAutostart => 'Turn on Autostart for Hopin';

  @override
  String get xiaomiBattery => 'Battery saver: No restrictions';

  @override
  String get samsungBattery => 'Battery: Unrestricted';

  @override
  String get samsungNeverSleeping => 'Add Hopin to Never sleeping apps';

  @override
  String get openSettings => 'Open settings';

  @override
  String get done => 'Done';

  @override
  String get channelGuide => 'Ride guide';

  @override
  String get channelAlerts => 'Stop alerts';

  @override
  String get guideFailed => 'The guide didn\'t start. Try again.';

  @override
  String get guideNeedsLocation => 'Turn on location to start a guide.';
}
