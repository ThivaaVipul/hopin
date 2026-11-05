// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'Hopin';

  @override
  String get tagline => 'உங்கள் நிறுத்தத்தைத் தவறவிடாதீர்கள்.';

  @override
  String get continueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get signInFailed =>
      'உள்நுழைய முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String hello(String name) {
    return 'வணக்கம், $name';
  }

  @override
  String get riderOn => 'பயணி அனுமதி இயக்கத்தில் உள்ளது';

  @override
  String get riderWaiting => 'பயணி அனுமதிக்காகக் காத்திருக்கிறது';

  @override
  String get checkAgain => 'மீண்டும் பார்';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get whereTo => 'எங்கே போக வேண்டும்?';

  @override
  String get add => 'சேர்';

  @override
  String get kindHome => 'வீடு';

  @override
  String get kindWork => 'வேலை';

  @override
  String get kindUni => 'பல்கலை';

  @override
  String get kindOther => 'மற்றவை';

  @override
  String get locationWhy =>
      'நீங்கள் எங்கே இருக்கிறீர்கள் என்று காட்டவும், உங்கள் நிறுத்தத்துக்கு முன் அதிர்வு தரவும் Hopin உங்கள் இருப்பிடத்தைப் பயன்படுத்துகிறது.';

  @override
  String get continueLabel => 'தொடர்க';

  @override
  String get notNow => 'இப்போது வேண்டாம்';

  @override
  String get turnOnLocation => 'இருப்பிடத்தை இயக்கு';

  @override
  String get showMe => 'நான் இருக்கும் இடம்';

  @override
  String get account => 'கணக்கு';

  @override
  String awayKm(String km) {
    return '$km கி.மீ தொலைவில்';
  }

  @override
  String awayM(String m) {
    return '$m மீ தொலைவில்';
  }

  @override
  String get droppedPin => 'குறித்த இடம்';

  @override
  String get save => 'சேமி';

  @override
  String get edit => 'திருத்து';

  @override
  String get close => 'மூடு';

  @override
  String get savePlace => 'இடத்தைச் சேமி';

  @override
  String get editPlace => 'இடத்தைத் திருத்து';

  @override
  String get placeName => 'பெயர்';

  @override
  String get delete => 'நீக்கு';

  @override
  String get recent => 'சமீபத்தியவை';

  @override
  String get search => 'தேடு';

  @override
  String get back => 'பின்';

  @override
  String get searchFailed =>
      'தேடல் வேலை செய்யவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get nothingFound => 'எதுவும் கிடைக்கவில்லை. வேறு பெயரில் தேடவும்.';

  @override
  String get start => 'தொடங்கு';

  @override
  String get end => 'முடி';

  @override
  String get getReady => 'தயாராகுங்கள்';

  @override
  String get getOffNext => 'அடுத்து இறங்குங்கள்';

  @override
  String get passedStop => 'உங்கள் நிறுத்தத்தைக் கடந்துவிட்டீர்கள்';

  @override
  String get arrived => 'வந்துசேர்ந்துவிட்டீர்கள்';

  @override
  String distanceKm(String km) {
    return '$km கி.மீ';
  }

  @override
  String distanceM(String m) {
    return '$m மீ';
  }

  @override
  String minutesLeft(int minutes) {
    return '$minutes நிமி';
  }

  @override
  String distanceTo(String distance, String place) {
    return '$place வரை $distance';
  }

  @override
  String nowNear(String place) {
    return 'இப்போது $place அருகில்';
  }

  @override
  String get findingYou => 'உங்களைக் கண்டறிகிறது';

  @override
  String get notificationsWhy =>
      'திரை அணைந்திருந்தாலும், Hopin வழிகாட்டலை அறிவிப்புகளில் காட்டி, உங்கள் நிறுத்தத்துக்கு முன் எச்சரிக்கும்.';

  @override
  String get keepRunning => 'Hopin தொடர்ந்து இயங்கட்டும்';

  @override
  String get xiaomiAutostart => 'Hopin க்கு Autostart ஐ இயக்குங்கள்';

  @override
  String get xiaomiBattery => 'Battery saver: No restrictions';

  @override
  String get samsungBattery => 'Battery: Unrestricted';

  @override
  String get samsungNeverSleeping =>
      'Never sleeping apps இல் Hopin ஐச் சேருங்கள்';

  @override
  String get openSettings => 'அமைப்புகளைத் திற';

  @override
  String get done => 'சரி';

  @override
  String get channelGuide => 'பயண வழிகாட்டி';

  @override
  String get channelAlerts => 'நிறுத்த எச்சரிக்கைகள்';

  @override
  String get guideFailed => 'வழிகாட்டி தொடங்கவில்லை. மீண்டும் முயலவும்.';

  @override
  String get guideNeedsLocation =>
      'வழிகாட்டியைத் தொடங்க இருப்பிடத்தை இயக்குங்கள்.';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get places => 'இடங்கள்';

  @override
  String get noPlaces => 'சேமித்த இடங்கள் இல்லை';

  @override
  String get reorder => 'இழுத்து வரிசை மாற்று';

  @override
  String get alerts => 'எச்சரிக்கைகள்';

  @override
  String get addStage => 'நிலையைச் சேர்';

  @override
  String get removeStage => 'நீக்கு';

  @override
  String get tryIt => 'சோதி';

  @override
  String get patternGentleDoubleTap => 'மெல்லிய இரட்டைத் தட்டு';

  @override
  String get patternStrongLongBuzz => 'வலுவான நீண்ட அதிர்வு';

  @override
  String get patternHeartbeat => 'இதயத் துடிப்பு';

  @override
  String get patternTripleKnock => 'மூன்று தட்டு';

  @override
  String get patternRising => 'ஏறுமுகம்';

  @override
  String get patternWaves => 'அலைகள்';

  @override
  String get language => 'மொழி';

  @override
  String get english => 'English';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get thisPhone => 'இந்தத் தொலைபேசி';

  @override
  String get notificationsOn => 'அறிவிப்புகள் இயக்கத்தில் உள்ளன';

  @override
  String get notificationsOff => 'அறிவிப்புகள் அணைந்துள்ளன';

  @override
  String get turnOn => 'இயக்கு';

  @override
  String get batteryGuide => 'பேட்டரி வழிகாட்டி';

  @override
  String get runsInBackground => 'Hopin பின்னணியில் இயங்கலாம்';

  @override
  String get mayBeStopped => 'உங்கள் தொலைபேசி Hopin ஐ நிறுத்தலாம்';

  @override
  String get updates => 'புதுப்பிப்புகள்';

  @override
  String versionLabel(String version) {
    return 'பதிப்பு $version';
  }

  @override
  String get devBuild => 'சோதனைப் பதிப்பு';

  @override
  String get checkUpdates => 'சரிபார்';

  @override
  String get upToDate => 'புதியதுதான்';

  @override
  String updateReady(String version) {
    return 'Hopin $version தயார்';
  }

  @override
  String get update => 'புதுப்பி';

  @override
  String downloading(int percent) {
    return 'பதிவிறக்குகிறது $percent%';
  }

  @override
  String get updateFailed => 'புதுப்பிப்பு பதிவிறங்கவில்லை. மீண்டும் முயலவும்.';

  @override
  String get allowInstalls =>
      'Hopin க்கு செயலிகளை நிறுவ அனுமதி தந்து, மீண்டும் புதுப்பி ஐத் தட்டவும்.';

  @override
  String stillGoing(String place) {
    return 'இன்னும் $place க்குப் போகிறீர்களா?';
  }

  @override
  String get keep => 'தொடர்';

  @override
  String get guideGaveUp => '2 மணி நேரமாக நெருங்காததால் வழிகாட்டி நின்றது.';

  @override
  String get checkFailed =>
      'சரிபார்க்க முடியவில்லை. இணையத்தைச் சரிபார்த்து மீண்டும் முயலவும்.';

  @override
  String get checkingRide => 'உங்கள் பயணத்தைச் சரிபார்க்கிறது';

  @override
  String get onABus => 'பஸ்ஸில் இருக்கிறீர்களா?';

  @override
  String get yes => 'ஆம்';

  @override
  String get notABus => 'பஸ் அல்ல';

  @override
  String get busRide => 'பஸ் பயணம்';

  @override
  String get noticeRides => 'பஸ் பயணங்களைக் கவனி';

  @override
  String get noticeWhy =>
      'Hopin உங்கள் பஸ் பயணங்களைக் கவனித்து, எங்கே இறங்குகிறீர்கள் என்று கேட்கும்.';

  @override
  String get needsAllTheTime =>
      'இருப்பிடம் \"Allow all the time\" ஆக இருக்க வேண்டும்';

  @override
  String get needsActivity => 'Physical activity அனுமதி தேவை';

  @override
  String get pretendRide => 'பயணம் தொடங்கியதாகக் கொள்';

  @override
  String get rides => 'பயணங்கள்';

  @override
  String get allRides => 'எல்லாப் பயணங்களும்';

  @override
  String get noRides => 'இன்னும் பயணங்கள் இல்லை';

  @override
  String get today => 'இன்று';

  @override
  String get yesterday => 'நேற்று';

  @override
  String get bus => 'பஸ்';

  @override
  String get unsure => 'தெரியாது';

  @override
  String get deleteRideQuestion => 'இந்தப் பயணத்தை நீக்கவா?';

  @override
  String get cancel => 'ரத்து';

  @override
  String get removePath => 'நீக்கு';

  @override
  String get notBusQuestion =>
      'பஸ் அல்லாத பயணத்துக்கு வழி சேமிக்கப்படாது. நீக்கவா?';

  @override
  String durationMinutes(int minutes) {
    return '$minutes நிமி';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours மணி $minutes நிமி';
  }

  @override
  String timeRange(String start, String end) {
    return '$start - $end';
  }

  @override
  String get share => 'பகிர்';

  @override
  String get sharingRide => 'இந்தப் பயணம் பகிரப்படுகிறது';

  @override
  String get sendLink => 'இணைப்பை அனுப்பு';

  @override
  String get stopSharing => 'பகிர்வதை நிறுத்து';

  @override
  String followMyRide(String link) {
    return 'என் பஸ் பயணத்தை நேரலையில் பாருங்கள்: $link';
  }

  @override
  String get sharedRide => 'பகிர்ந்த பயணம்';

  @override
  String sharedRideTo(String stop) {
    return '$stop நோக்கிப் பகிர்ந்த பயணம்';
  }

  @override
  String get watch => 'பார்';

  @override
  String get updatedJustNow => 'இப்போது புதுப்பிக்கப்பட்டது';

  @override
  String updatedSecondsAgo(int seconds) {
    return '$seconds வினாடி முன் புதுப்பிக்கப்பட்டது';
  }

  @override
  String updatedMinutesAgo(int minutes) {
    return '$minutes நிமி முன் புதுப்பிக்கப்பட்டது';
  }

  @override
  String get lostContact => 'தொடர்பு இல்லை';

  @override
  String get shareRidesHere => 'இங்கு செல்லும் பயணங்களைப் பகிர்';

  @override
  String get busStop => 'பஸ் நிறுத்தம்';

  @override
  String get renameStop => 'பெயர் மாற்று';

  @override
  String get removeStop => 'நீக்கு';

  @override
  String get stopName => 'நிறுத்தத்தின் பெயர்';

  @override
  String get removeStopQuestion => 'இந்த நிறுத்தத்தை இருவருக்கும் நீக்கவா?';

  @override
  String get moreOptions => 'மேலும்';

  @override
  String get noBusKnown => 'தெரிந்த பஸ் இன்னும் இல்லை';

  @override
  String get showName => 'காட்டு';

  @override
  String boardAt(String stop) {
    return '$stop இல் ஏறுங்கள்';
  }

  @override
  String get boardOnRoad => 'இந்த வீதியில் ஏறுங்கள்';

  @override
  String get boardAtStand => 'பஸ் நிலையத்தில் ஏறுங்கள்';

  @override
  String walkM(String m) {
    return '$m மீ நடை';
  }

  @override
  String walkKm(String km) {
    return '$km கி.மீ நடை';
  }

  @override
  String get allTimes => 'எல்லா நேரங்களும்';

  @override
  String timesAt(String stop) {
    return '$stop நேரங்கள்';
  }

  @override
  String get tomorrow => 'நாளை';

  @override
  String get noneLeftToday => 'இன்று இனி இல்லை';

  @override
  String alsoNumbers(String numbers) {
    return 'மேலும் $numbers';
  }

  @override
  String get classNormal => 'சாதாரண';

  @override
  String get classSemiLuxury => 'அரை சொகுசு';

  @override
  String get classLuxury => 'சொகுசு';

  @override
  String get classAc => 'ஏசி';

  @override
  String get classExpressway => 'அதிவேக';

  @override
  String get routeCredits => 'வழிகள்: OpenStreetMap, OSRM, NTC, LMT';

  @override
  String get routes => 'வழிகள்';

  @override
  String get allRoutes => 'எல்லா வழிகளும்';

  @override
  String get routeNumberHint => 'வழி எண்';

  @override
  String get noRoutes => 'இன்னும் வழிகள் இல்லை';

  @override
  String noRouteNumbered(String number) {
    return '$number எண் வழி இல்லை';
  }

  @override
  String routeEnds(String from, String to) {
    return '$from முதல் $to வரை';
  }

  @override
  String routeVia(String towns) {
    return '$towns வழியாக';
  }

  @override
  String get routeRemoved => 'நீக்கப்பட்டது';

  @override
  String get removeRoute => 'நீக்கு';

  @override
  String get removeRouteQuestion => 'இந்த வழியை இருவருக்கும் நீக்கவா?';

  @override
  String get putBackRoute => 'மீண்டும் சேர்';

  @override
  String get editBoard => 'பலகையைத் திருத்து';

  @override
  String get boardEdited => 'திருத்தப்பட்டது';

  @override
  String get lineTamil => 'தமிழ்';

  @override
  String get lineSinhala => 'சிங்களம்';

  @override
  String get lineEnglish => 'ஆங்கிலம்';

  @override
  String get routeSourceOsm => 'OpenStreetMap';

  @override
  String get routeSourceNtc => 'NTC நேர அட்டவணை';

  @override
  String get routeSourceLmt => 'LMT மெட்ரோ';

  @override
  String get guessedDashed => 'இடைவிட்ட கோடு: ஊகித்த வீதி';
}
