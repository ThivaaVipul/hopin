import 'package:equatable/equatable.dart';
import 'package:hopin/core/ride/guide.dart';
import 'package:hopin/core/ride/patterns.dart';
import 'package:hopin/core/ride/ride_config.dart';
import 'package:hopin/core/ride/ride_record.dart';
import 'package:hopin/core/ride/routes.dart';

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

/// The ride service asks "On a bus?" (its card shows on Home).
class RideQuestion extends GuideEvent {
  const RideQuestion();

  @override
  List<Object?> get props => [];
}

/// "On a bus?" was answered, here or in the notification.
class RideAnswered extends GuideEvent {
  const RideAnswered();

  @override
  List<Object?> get props => [];
}

/// A place button in "On a bus?" started a guide to [ride].
class GuideStarted extends GuideEvent {
  const GuideStarted(this.ride);

  final GuideRide ride;

  @override
  List<Object?> get props => [ride];
}

/// A ride ended and was handed over to be kept.
class RideLogged extends GuideEvent {
  const RideLogged(this.ride);

  final RideRecord ride;

  @override
  List<Object?> get props => [ride];
}

/// The ride's share started under [id], or stopped (null).
class ShareChanged extends GuideEvent {
  const ShareChanged(this.id);

  final String? id;

  @override
  List<Object?> get props => [id];
}

/// The running ride's bus, as tagged ("Which bus?"), or untagged (null).
class RideTagged extends GuideEvent {
  const RideTagged(this.tag);

  final RouteTag? tag;

  @override
  List<Object?> get props => [tag];
}

/// A bus ride with no guide is on, since [since]: Home shows its bar.
class RideNoticed extends GuideEvent {
  const RideNoticed(this.since);

  final DateTime since;

  @override
  List<Object?> get props => [since];
}

/// Whether Hopin notices bus rides (docs/PLAN.md, Ride detection), and the
/// two permissions it needs.
class Detection extends Equatable {
  const Detection({
    this.on = false,
    this.activity = false,
    this.allTheTime = false,
  });

  /// Turned on and both permissions there.
  final bool on;
  final bool activity;
  final bool allTheTime;

  @override
  List<Object?> get props => [on, activity, allTheTime];
}

/// Makers whose phones stop background apps unless told not to
/// (docs/ARCHITECTURE.md, Phones that kill background apps).
enum PhoneMaker { xiaomi, samsung, other }

/// The get-off guide as the screens see it: a foreground service that runs
/// on with the app closed, plus the phone settings it needs.
abstract interface class GuideService {
  /// The guide running now, if any; it outlives the app's screens.
  Future<GuideRide?> running();

  /// Whether the ride service runs at all (a guide, or a watched ride).
  Future<bool> serviceRunning();

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

  /// Answers "On a bus?" with one of ride_task.dart's button IDs.
  Future<void> answer(String button);

  /// What the service needs when it wakes with Hopin closed.
  Future<void> saveRideConfig(RideConfig config);

  /// Rides the service finished while the app wasn't there to take them.
  Future<List<RideRecord>> pendingRides();

  /// The app keeps [id] now.
  Future<void> forgetPendingRide(String id);

  Future<Detection> detection();

  /// Physical activity, then location all the time, then on.
  Future<Detection> turnOnDetection(String language);

  Future<void> turnOffDetection();

  /// Test builds: starts watching a ride now, without a vehicle.
  Future<void> detectNow();

  /// Shares the running ride under [id] (its link is shareLink(id)); the
  /// service answers with [ShareChanged].
  Future<void> share(String id);

  Future<void> stopSharing();

  /// Tags the running ride with its bus ("Which bus?"), or untags it; the
  /// service keeps it with the ride and answers with [RideTagged].
  Future<void> tag(RouteTag? tag);
}
