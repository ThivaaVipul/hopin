import 'package:hopin/l10n/app_localizations.dart';

/// Time left to a stop: "12 min", or on a long trip "14 h 49 min".
extension TimeLeft on AppLocalizations {
  String timeLeft(int minutes) => minutes < 60
      ? minutesLeft(minutes)
      : durationHours(minutes ~/ 60, minutes % 60);
}
