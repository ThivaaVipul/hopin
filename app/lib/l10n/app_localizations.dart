import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ta.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
  ];

  /// The app's name. A brand name: kept as is in every language.
  ///
  /// In en, this message translates to:
  /// **'Hopin'**
  String get appTitle;

  /// One line under the name on the sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Never miss your stop.'**
  String get tagline;

  /// The sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Shown when Google sign-in fails for a reason other than the person closing it.
  ///
  /// In en, this message translates to:
  /// **'Sign-in didn\'t work. Check your internet and try again.'**
  String get signInFailed;

  /// Greeting on the home page.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name}'**
  String hello(String name);

  /// The account can sync: the owner has made it a rider.
  ///
  /// In en, this message translates to:
  /// **'Rider access is on'**
  String get riderOn;

  /// Signed in, but the owner hasn't made the account a rider yet; nothing syncs until then.
  ///
  /// In en, this message translates to:
  /// **'Waiting for rider access'**
  String get riderWaiting;

  /// Looks again for rider access.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get checkAgain;

  /// Signs out of the app.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// The search bar on Home and the search field.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get whereTo;

  /// Chip that opens search to save a new place.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Kind of saved place.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get kindHome;

  /// Kind of saved place.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get kindWork;

  /// Kind of saved place: university.
  ///
  /// In en, this message translates to:
  /// **'Uni'**
  String get kindUni;

  /// Kind of saved place.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get kindOther;

  /// The one-time card before Android asks for location.
  ///
  /// In en, this message translates to:
  /// **'Hopin uses your location to show where you are and to buzz before your stop.'**
  String get locationWhy;

  /// Goes on to Android's location popup.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Skips location for now.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Asks for location again after it was refused.
  ///
  /// In en, this message translates to:
  /// **'Turn on location'**
  String get turnOnLocation;

  /// Tooltip of the button that moves the map to you.
  ///
  /// In en, this message translates to:
  /// **'Show where I am'**
  String get showMe;

  /// Tooltip of the button that opens the account sheet.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Straight-line distance from you, in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km away'**
  String awayKm(String km);

  /// Straight-line distance from you, in metres.
  ///
  /// In en, this message translates to:
  /// **'{m} m away'**
  String awayM(String m);

  /// Title of a place picked by long-pressing the map, before or without a name.
  ///
  /// In en, this message translates to:
  /// **'Dropped pin'**
  String get droppedPin;

  /// Saves a place.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Edits a saved place.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Closes the destination sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Title of the sheet that saves a new place.
  ///
  /// In en, this message translates to:
  /// **'Save place'**
  String get savePlace;

  /// Title of the sheet that edits a saved place.
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// Field for a saved place's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get placeName;

  /// Deletes a saved place.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Heading over the last few destinations in search.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recent;

  /// Runs the search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Leaves search.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Shown when Nominatim cannot be reached.
  ///
  /// In en, this message translates to:
  /// **'Search didn\'t work. Check your internet and try again.'**
  String get searchFailed;

  /// Shown when a search finds no place.
  ///
  /// In en, this message translates to:
  /// **'Nothing found. Try another name.'**
  String get nothingFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
