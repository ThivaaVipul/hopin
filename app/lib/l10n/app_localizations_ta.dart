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
}
