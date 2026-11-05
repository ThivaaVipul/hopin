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

  /// Starts the get-off guide to the chosen place.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// Ends the guide, on the ride board and in its notification.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// An earlier alert stage: your stop is coming up.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get getReady;

  /// The last alert stage: get off at the next stop. The board turns amber.
  ///
  /// In en, this message translates to:
  /// **'Get off next'**
  String get getOffNext;

  /// Urgent alert: the bus went past the stop.
  ///
  /// In en, this message translates to:
  /// **'You passed your stop'**
  String get passedStop;

  /// Shown when the guide ends by itself at the stop.
  ///
  /// In en, this message translates to:
  /// **'You\'ve arrived'**
  String get arrived;

  /// A distance in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String distanceKm(String km);

  /// A distance in metres.
  ///
  /// In en, this message translates to:
  /// **'{m} m'**
  String distanceM(String m);

  /// Time left to the stop, in minutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesLeft(int minutes);

  /// In the guide notification: how far to the stop.
  ///
  /// In en, this message translates to:
  /// **'{distance} to {place}'**
  String distanceTo(String distance, String place);

  /// On the ride board: the area you are passing.
  ///
  /// In en, this message translates to:
  /// **'Now near {place}'**
  String nowNear(String place);

  /// The guide is waiting for its first GPS fix.
  ///
  /// In en, this message translates to:
  /// **'Finding you'**
  String get findingYou;

  /// The one-time card before Android asks for notifications.
  ///
  /// In en, this message translates to:
  /// **'Hopin shows the guide in your notifications and alerts you before your stop, even with the screen off.'**
  String get notificationsWhy;

  /// Title of the phone maker's battery steps, shown at the first guide.
  ///
  /// In en, this message translates to:
  /// **'Keep Hopin running'**
  String get keepRunning;

  /// Xiaomi phones: first battery step. "Autostart" is the setting's name on the phone.
  ///
  /// In en, this message translates to:
  /// **'Turn on Autostart for Hopin'**
  String get xiaomiAutostart;

  /// Xiaomi phones: second battery step, in the app's settings. Setting names as on the phone.
  ///
  /// In en, this message translates to:
  /// **'Battery saver: No restrictions'**
  String get xiaomiBattery;

  /// Samsung phones: first battery step, in the app's settings. Setting names as on the phone.
  ///
  /// In en, this message translates to:
  /// **'Battery: Unrestricted'**
  String get samsungBattery;

  /// Samsung phones: second battery step, under Battery in the phone's settings.
  ///
  /// In en, this message translates to:
  /// **'Add Hopin to Never sleeping apps'**
  String get samsungNeverSleeping;

  /// Opens the phone's settings for Hopin.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// Closes the battery steps.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Android's name for the guide's ongoing notification.
  ///
  /// In en, this message translates to:
  /// **'Ride guide'**
  String get channelGuide;

  /// Android's name for the alerts before your stop.
  ///
  /// In en, this message translates to:
  /// **'Stop alerts'**
  String get channelAlerts;

  /// Shown when Android refuses to start the guide.
  ///
  /// In en, this message translates to:
  /// **'The guide didn\'t start. Try again.'**
  String get guideFailed;

  /// Shown when Start is pressed without location access.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to start a guide.'**
  String get guideNeedsLocation;

  /// The Settings page and the button that opens it.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Settings section: saved places.
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get places;

  /// Settings, Places, when there are none.
  ///
  /// In en, this message translates to:
  /// **'No saved places yet'**
  String get noPlaces;

  /// Tooltip of a saved place's drag handle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get reorder;

  /// Settings section: the alert stages before your stop.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alerts;

  /// Adds an alert stage (up to three).
  ///
  /// In en, this message translates to:
  /// **'Add a stage'**
  String get addStage;

  /// Removes an alert stage.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeStage;

  /// Plays a vibration pattern as the alert would.
  ///
  /// In en, this message translates to:
  /// **'Try'**
  String get tryIt;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Gentle double tap'**
  String get patternGentleDoubleTap;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Strong long buzz'**
  String get patternStrongLongBuzz;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Heartbeat'**
  String get patternHeartbeat;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Triple knock'**
  String get patternTripleKnock;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Rising'**
  String get patternRising;

  /// Vibration pattern name.
  ///
  /// In en, this message translates to:
  /// **'Waves'**
  String get patternWaves;

  /// Settings section: the app's language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// The English language, written in English in every language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// The Tamil language, written in Tamil in every language.
  ///
  /// In en, this message translates to:
  /// **'தமிழ்'**
  String get tamil;

  /// Settings section: notifications and the battery guide.
  ///
  /// In en, this message translates to:
  /// **'This phone'**
  String get thisPhone;

  /// Settings: notifications are allowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are on'**
  String get notificationsOn;

  /// Settings: notifications are not allowed.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off'**
  String get notificationsOff;

  /// Turns notifications on.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// Opens Android's background popup and the maker's steps.
  ///
  /// In en, this message translates to:
  /// **'Battery guide'**
  String get batteryGuide;

  /// Settings: Android lets Hopin run in the background.
  ///
  /// In en, this message translates to:
  /// **'Hopin can run in the background'**
  String get runsInBackground;

  /// Settings: Android may stop Hopin in the background.
  ///
  /// In en, this message translates to:
  /// **'Your phone may stop Hopin'**
  String get mayBeStopped;

  /// Settings section: the version and updates.
  ///
  /// In en, this message translates to:
  /// **'Updates'**
  String get updates;

  /// The installed version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// Shown instead of a version on builds made outside the release workflow.
  ///
  /// In en, this message translates to:
  /// **'Test build'**
  String get devBuild;

  /// Looks for a newer version now.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get checkUpdates;

  /// No newer version.
  ///
  /// In en, this message translates to:
  /// **'Up to date'**
  String get upToDate;

  /// A newer version is out.
  ///
  /// In en, this message translates to:
  /// **'Hopin {version} is ready'**
  String updateReady(String version);

  /// Downloads and installs the newer version.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Update download progress.
  ///
  /// In en, this message translates to:
  /// **'Downloading {percent}%'**
  String downloading(int percent);

  /// Shown when the download fails.
  ///
  /// In en, this message translates to:
  /// **'The update didn\'t download. Try again.'**
  String get updateFailed;

  /// Shown after Android's install permission page opens.
  ///
  /// In en, this message translates to:
  /// **'Allow Hopin to install apps, then tap Update again.'**
  String get allowInstalls;

  /// Asked when a guide gets no closer for 20 minutes.
  ///
  /// In en, this message translates to:
  /// **'Still going to {place}?'**
  String stillGoing(String place);

  /// Keeps the guide going.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Shown when a guide ends itself after 2 hours without getting closer.
  ///
  /// In en, this message translates to:
  /// **'The guide stopped: no closer in 2 hours.'**
  String get guideGaveUp;

  /// Shown when looking for a newer version fails.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check. Check your internet and try again.'**
  String get checkFailed;

  /// The ride service's notification while it watches a vehicle ride.
  ///
  /// In en, this message translates to:
  /// **'Checking your ride'**
  String get checkingRide;

  /// Asked when a vehicle ride looks like a bus.
  ///
  /// In en, this message translates to:
  /// **'On a bus?'**
  String get onABus;

  /// Answers "On a bus?" when there are fewer than two saved places.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Answers "On a bus?": the ride was a car, tuk-tuk or bike.
  ///
  /// In en, this message translates to:
  /// **'Not a bus'**
  String get notABus;

  /// The ride service's notification after Yes.
  ///
  /// In en, this message translates to:
  /// **'On a bus'**
  String get busRide;

  /// Settings switch: Hopin notices bus rides by itself.
  ///
  /// In en, this message translates to:
  /// **'Notice bus rides'**
  String get noticeRides;

  /// The one-time card on Home that offers ride detection.
  ///
  /// In en, this message translates to:
  /// **'Hopin can notice your bus rides and ask where you are getting off.'**
  String get noticeWhy;

  /// Settings, under the switch, when background location is missing.
  ///
  /// In en, this message translates to:
  /// **'Needs location set to Allow all the time'**
  String get needsAllTheTime;

  /// Settings, under the switch, when activity recognition is missing.
  ///
  /// In en, this message translates to:
  /// **'Needs Physical activity'**
  String get needsActivity;

  /// Test builds only: starts ride detection without a real vehicle.
  ///
  /// In en, this message translates to:
  /// **'Pretend a ride started'**
  String get pretendRide;

  /// Settings: the section for logged rides, and the Rides page's title.
  ///
  /// In en, this message translates to:
  /// **'Rides'**
  String get rides;

  /// Settings: opens the list of logged rides.
  ///
  /// In en, this message translates to:
  /// **'All rides'**
  String get allRides;

  /// The Rides page with nothing logged.
  ///
  /// In en, this message translates to:
  /// **'No rides yet'**
  String get noRides;

  /// A day heading in the rides list.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// A day heading in the rides list.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// A ride's label: it was a bus.
  ///
  /// In en, this message translates to:
  /// **'Bus'**
  String get bus;

  /// A ride's label: not answered or not known.
  ///
  /// In en, this message translates to:
  /// **'Unsure'**
  String get unsure;

  /// Asked before a ride is deleted.
  ///
  /// In en, this message translates to:
  /// **'Delete this ride?'**
  String get deleteRideQuestion;

  /// Leaves a question without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirms marking a ride Not a bus, which removes its path.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removePath;

  /// Asked before a ride with a path is marked Not a bus.
  ///
  /// In en, this message translates to:
  /// **'Not a bus keeps no path. Remove it?'**
  String get notBusQuestion;

  /// A ride's duration under an hour.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String durationMinutes(int minutes);

  /// A ride's duration of an hour or more.
  ///
  /// In en, this message translates to:
  /// **'{hours} h {minutes} min'**
  String durationHours(int hours, int minutes);

  /// A ride's start and end times.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}'**
  String timeRange(String start, String end);

  /// The ride's Share button.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// The ride is being shared live.
  ///
  /// In en, this message translates to:
  /// **'Sharing this ride'**
  String get sharingRide;

  /// Sends the ride's link again.
  ///
  /// In en, this message translates to:
  /// **'Send link'**
  String get sendLink;

  /// Ends the live share.
  ///
  /// In en, this message translates to:
  /// **'Stop sharing'**
  String get stopSharing;

  /// The message sent with the link.
  ///
  /// In en, this message translates to:
  /// **'Follow my bus ride live: {link}'**
  String followMyRide(String link);

  /// The other rider's share, with no destination.
  ///
  /// In en, this message translates to:
  /// **'Shared ride'**
  String get sharedRide;

  /// The other rider's share, going to a stop.
  ///
  /// In en, this message translates to:
  /// **'Shared ride to {stop}'**
  String sharedRideTo(String stop);

  /// Shows the other rider's share on the map.
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get watch;

  /// When the shared position last changed.
  ///
  /// In en, this message translates to:
  /// **'Updated just now'**
  String get updatedJustNow;

  /// When the shared position last changed.
  ///
  /// In en, this message translates to:
  /// **'Updated {seconds} s ago'**
  String updatedSecondsAgo(int seconds);

  /// When the shared position last changed.
  ///
  /// In en, this message translates to:
  /// **'Updated {minutes} min ago'**
  String updatedMinutesAgo(int minutes);

  /// No update from the shared ride for 10 minutes.
  ///
  /// In en, this message translates to:
  /// **'Lost contact'**
  String get lostContact;

  /// The place editor: a guide here shares the ride by itself.
  ///
  /// In en, this message translates to:
  /// **'Share rides here'**
  String get shareRidesHere;

  /// A stop on the map, in its panel.
  ///
  /// In en, this message translates to:
  /// **'Bus stop'**
  String get busStop;

  /// Renames a learned stop for both riders.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get renameStop;

  /// Removes a learned stop for both riders.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeStop;

  /// The rename field's label.
  ///
  /// In en, this message translates to:
  /// **'Stop name'**
  String get stopName;

  /// Asked before a learned stop is removed.
  ///
  /// In en, this message translates to:
  /// **'Remove this stop for both of you?'**
  String get removeStopQuestion;

  /// A stop panel's menu of Rename and Remove.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreOptions;

  /// The destination panel, when no known bus goes there from here.
  ///
  /// In en, this message translates to:
  /// **'No bus known yet'**
  String get noBusKnown;

  /// Shows the place's name full screen, to show a conductor or someone at the stop and ask which bus goes there.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showName;

  /// Where to get on a bus in the destination panel.
  ///
  /// In en, this message translates to:
  /// **'Board at {stop}'**
  String boardAt(String stop);

  /// Where to get on when the route lists no stop near you.
  ///
  /// In en, this message translates to:
  /// **'Board on this road'**
  String get boardOnRoad;

  /// Where to get on a long-distance bus whose bus stand has no name.
  ///
  /// In en, this message translates to:
  /// **'Board at the bus stand'**
  String get boardAtStand;

  /// How far you walk to the bus, in metres.
  ///
  /// In en, this message translates to:
  /// **'{m} m walk'**
  String walkM(String m);

  /// How far you walk (or go) to the bus, in kilometres.
  ///
  /// In en, this message translates to:
  /// **'{km} km walk'**
  String walkKm(String km);

  /// Opens a bus's times for today where you board.
  ///
  /// In en, this message translates to:
  /// **'All times'**
  String get allTimes;

  /// The title of a bus's times for today.
  ///
  /// In en, this message translates to:
  /// **'Times at {stop}'**
  String timesAt(String stop);

  /// Before a bus time that is tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// A bus's times when none are left today.
  ///
  /// In en, this message translates to:
  /// **'None left today'**
  String get noneLeftToday;

  /// Other route numbers the same buses may show.
  ///
  /// In en, this message translates to:
  /// **'also {numbers}'**
  String alsoNumbers(String numbers);

  /// A bus class: normal service.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get classNormal;

  /// A bus class.
  ///
  /// In en, this message translates to:
  /// **'Semi luxury'**
  String get classSemiLuxury;

  /// A bus class.
  ///
  /// In en, this message translates to:
  /// **'Luxury'**
  String get classLuxury;

  /// A bus class: air conditioned.
  ///
  /// In en, this message translates to:
  /// **'AC'**
  String get classAc;

  /// A bus class: runs on the expressway.
  ///
  /// In en, this message translates to:
  /// **'Expressway'**
  String get classExpressway;

  /// Where the bus routes and times come from, under the buses.
  ///
  /// In en, this message translates to:
  /// **'Routes: OpenStreetMap, OSRM, NTC, LMT'**
  String get routeCredits;
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
