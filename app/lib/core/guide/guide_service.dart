import 'package:equatable/equatable.dart';
import 'package:hopin/core/ride/guide.dart';

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

/// The guide stopped: by itself at the stop ([arrived]), or from its
/// notification's End.
class GuideEnded extends GuideEvent {
  const GuideEnded({required this.arrived});

  final bool arrived;

  @override
  List<Object?> get props => [arrived];
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
}
