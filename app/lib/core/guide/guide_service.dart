import 'package:equatable/equatable.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';

/// News from the running guide while the app is open.
sealed class GuideEvent extends Equatable {
  const GuideEvent();
}

class GuideUpdate extends GuideEvent {
  const GuideUpdate(this.status);

  final GuideStatus status;

  @override
  List<Object?> get props => [status];
}

/// The guide stopped: by itself at the stop ([arrived]), by itself after two
/// hours without getting closer ([gaveUp]), or from its notification's End.
class GuideEnded extends GuideEvent {
  const GuideEnded({required this.arrived, this.gaveUp = false});

  final bool arrived;
  final bool gaveUp;

  @override
  List<Object?> get props => [arrived, gaveUp];
}

/// Makers whose phones stop background apps unless told not to
/// (docs/ARCHITECTURE.md, Phones that kill background apps).
enum PhoneMaker { xiaomi, samsung, other }

/// The get-off guide as the screens see it: a foreground service that runs
/// on with the app closed, plus the phone settings it needs.
abstract interface class GuideService {
  /// The guide running now, if any; it outlives the app's screens.
  Future<GuideRide?> running();

  /// Starts a guide; false when Android refuses.
  Future<bool> start(GuideRide ride);

  Future<void> end();

  /// Keep, while the guide asks "Still going to (stop)?".
  Future<void> keepGoing();

  Stream<GuideEvent> get events;

  Future<bool> notificationsAllowed();

  /// Android's notification popup; true once allowed.
  Future<bool> askForNotifications();

  /// Android's own popup to let Hopin run in the background, unless it
  /// already may.
  Future<void> askToRunInBackground();

  Future<PhoneMaker> maker();

  /// The maker's own settings for Hopin, where Android allows it.
  Future<void> openMakerSettings();

  /// Whether Android lets Hopin run in the background (the battery guide).
  Future<bool> runsInBackground();

  /// Hopin's page in Android's settings, for notifications refused for good.
  Future<void> openAppSettings();

  /// Plays [buzz] now, for "try it".
  Future<void> play(Buzz buzz);
}
