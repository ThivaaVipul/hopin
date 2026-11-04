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

  @override
  String get settings => 'Settings';

  @override
  String get places => 'Places';

  @override
  String get noPlaces => 'No saved places yet';

  @override
  String get reorder => 'Drag to reorder';

  @override
  String get alerts => 'Alerts';

  @override
  String get addStage => 'Add a stage';

  @override
  String get removeStage => 'Remove';

  @override
  String get tryIt => 'Try';

  @override
  String get patternGentleDoubleTap => 'Gentle double tap';

  @override
  String get patternStrongLongBuzz => 'Strong long buzz';

  @override
  String get patternHeartbeat => 'Heartbeat';

  @override
  String get patternTripleKnock => 'Triple knock';

  @override
  String get patternRising => 'Rising';

  @override
  String get patternWaves => 'Waves';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get thisPhone => 'This phone';

  @override
  String get notificationsOn => 'Notifications are on';

  @override
  String get notificationsOff => 'Notifications are off';

  @override
  String get turnOn => 'Turn on';

  @override
  String get batteryGuide => 'Battery guide';

  @override
  String get runsInBackground => 'Hopin can run in the background';

  @override
  String get mayBeStopped => 'Your phone may stop Hopin';

  @override
  String get updates => 'Updates';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get devBuild => 'Test build';

  @override
  String get checkUpdates => 'Check';

  @override
  String get upToDate => 'Up to date';

  @override
  String updateReady(String version) {
    return 'Hopin $version is ready';
  }

  @override
  String get update => 'Update';

  @override
  String downloading(int percent) {
    return 'Downloading $percent%';
  }

  @override
  String get updateFailed => 'The update didn\'t download. Try again.';

  @override
  String get allowInstalls =>
      'Allow Hopin to install apps, then tap Update again.';

  @override
  String stillGoing(String place) {
    return 'Still going to $place?';
  }

  @override
  String get keep => 'Keep';

  @override
  String get guideGaveUp => 'The guide stopped: no closer in 2 hours.';

  @override
  String get checkFailed =>
      'Couldn\'t check. Check your internet and try again.';

  @override
  String get checkingRide => 'Checking your ride';

  @override
  String get onABus => 'On a bus?';

  @override
  String get yes => 'Yes';

  @override
  String get notABus => 'Not a bus';

  @override
  String get busRide => 'On a bus';

  @override
  String get noticeRides => 'Notice bus rides';

  @override
  String get noticeWhy =>
      'Hopin can notice your bus rides and ask where you are getting off.';

  @override
  String get needsAllTheTime => 'Needs location set to Allow all the time';

  @override
  String get needsActivity => 'Needs Physical activity';

  @override
  String get pretendRide => 'Pretend a ride started';

  @override
  String get rides => 'Rides';

  @override
  String get allRides => 'All rides';

  @override
  String get noRides => 'No rides yet';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get bus => 'Bus';

  @override
  String get unsure => 'Unsure';

  @override
  String get deleteRideQuestion => 'Delete this ride?';

  @override
  String get cancel => 'Cancel';

  @override
  String get removePath => 'Remove';

  @override
  String get notBusQuestion => 'Not a bus keeps no path. Remove it?';

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String timeRange(String start, String end) {
    return '$start - $end';
  }
}
