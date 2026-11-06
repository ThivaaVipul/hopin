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

  @override
  String get share => 'Share';

  @override
  String get sharingRide => 'Sharing this ride';

  @override
  String get sendLink => 'Send link';

  @override
  String get stopSharing => 'Stop sharing';

  @override
  String followMyRide(String link) {
    return 'Follow my bus ride live: $link';
  }

  @override
  String get sharedRide => 'Shared ride';

  @override
  String sharedRideTo(String stop) {
    return 'Shared ride to $stop';
  }

  @override
  String get watch => 'Watch';

  @override
  String get updatedJustNow => 'Updated just now';

  @override
  String updatedSecondsAgo(int seconds) {
    return 'Updated $seconds s ago';
  }

  @override
  String updatedMinutesAgo(int minutes) {
    return 'Updated $minutes min ago';
  }

  @override
  String get lostContact => 'Lost contact';

  @override
  String get shareRidesHere => 'Share rides here';

  @override
  String get busStop => 'Bus stop';

  @override
  String get renameStop => 'Rename';

  @override
  String get removeStop => 'Remove';

  @override
  String get stopName => 'Stop name';

  @override
  String get removeStopQuestion => 'Remove this stop for both of you?';

  @override
  String get moreOptions => 'More';

  @override
  String get noBusKnown => 'No bus known yet';

  @override
  String get showName => 'Show';

  @override
  String boardAt(String stop) {
    return 'Board at $stop';
  }

  @override
  String get boardOnRoad => 'Board on this road';

  @override
  String get boardAtStand => 'Board at the bus stand';

  @override
  String walkM(String m) {
    return '$m m walk';
  }

  @override
  String walkKm(String km) {
    return '$km km walk';
  }

  @override
  String get allTimes => 'All times';

  @override
  String timesAt(String stop) {
    return 'Times at $stop';
  }

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get noneLeftToday => 'None left today';

  @override
  String alsoNumbers(String numbers) {
    return 'also $numbers';
  }

  @override
  String get classNormal => 'Normal';

  @override
  String get classSemiLuxury => 'Semi luxury';

  @override
  String get classLuxury => 'Luxury';

  @override
  String get classAc => 'AC';

  @override
  String get classExpressway => 'Expressway';

  @override
  String get routeCredits => 'Routes: OpenStreetMap, OSRM, NTC, LMT';

  @override
  String get routes => 'Routes';

  @override
  String get allRoutes => 'All routes';

  @override
  String get routeNumberHint => 'Route number';

  @override
  String get noRoutes => 'No routes yet';

  @override
  String noRouteNumbered(String number) {
    return 'No route numbered $number';
  }

  @override
  String routeEnds(String from, String to) {
    return '$from to $to';
  }

  @override
  String routeVia(String towns) {
    return 'Via $towns';
  }

  @override
  String get routeRemoved => 'Removed';

  @override
  String get removeRoute => 'Remove';

  @override
  String get removeRouteQuestion => 'Remove this route for both of you?';

  @override
  String get putBackRoute => 'Put back';

  @override
  String get editBoard => 'Edit board';

  @override
  String get boardEdited => 'Edited';

  @override
  String get lineTamil => 'Tamil';

  @override
  String get lineSinhala => 'Sinhala';

  @override
  String get lineEnglish => 'English';

  @override
  String get routeSourceOsm => 'OpenStreetMap';

  @override
  String get routeSourceNtc => 'NTC timetable';

  @override
  String get routeSourceLmt => 'LMT Metro';

  @override
  String get guessedDashed => 'Dashed: guessed road';

  @override
  String get routeSourceHand => 'Added in Hopin';

  @override
  String get addRoute => 'Add a route';

  @override
  String get editRoute => 'Edit route';

  @override
  String get routeNumberLabel => 'Number';

  @override
  String get routeFrom => 'From';

  @override
  String get routeTo => 'To';

  @override
  String get pickTown => 'Pick a town';

  @override
  String get townsOnTheWay => 'Towns on the way';

  @override
  String get addTown => 'Add a town';

  @override
  String get removeTown => 'Remove town';

  @override
  String get searchTown => 'Search for a town';

  @override
  String get drawingRoad => 'Drawing the road';

  @override
  String get roadFailed =>
      'Couldn\'t draw the road. Check your internet and try again.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get editTowns => 'Edit towns';

  @override
  String get deleteRouteQuestion => 'Delete this route for both of you?';

  @override
  String get whichBus => 'Which bus?';

  @override
  String busTo(String number, String board) {
    return '$number to $board';
  }

  @override
  String get alongThisRide => 'Along this ride';

  @override
  String get nearYou => 'Near you';

  @override
  String addRouteNumbered(String number) {
    return 'Add $number';
  }

  @override
  String get notThisBus => 'Not this bus';

  @override
  String riddenTimes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ridden $count times',
      one: 'Ridden once',
    );
    return '$_temp0';
  }
}
