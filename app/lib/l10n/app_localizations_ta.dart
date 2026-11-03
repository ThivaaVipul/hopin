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
  String get mapNext => 'அடுத்த புதுப்பிப்பில் வரைபடம் வரும்.';

  @override
  String get signOut => 'வெளியேறு';
}
