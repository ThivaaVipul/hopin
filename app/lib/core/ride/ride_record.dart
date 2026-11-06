import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/polyline.dart';
import 'package:hopin/core/ride/routes.dart';

/// The rider's answer to "On a bus?", or the guide's word for it.
enum RideVerdict {
  bus('bus'),
  notBus('not_bus'),
  unknown('unknown');

  const RideVerdict(this.code);

  /// As stored in Firestore.
  final String code;

  static RideVerdict of(Object? code) => values.firstWhere(
    (v) => v.code == code,
    orElse: () => RideVerdict.unknown,
  );
}

/// One logged vehicle ride (docs/PLAN.md, Ride detection). A ride that was
/// not a bus keeps no path, halts or names.
class RideRecord extends Equatable {
  const RideRecord({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.verdict,
    required this.distanceM,
    this.path = const [],
    this.halts = const [],
    this.features = const {},
    this.guideTo,
    this.fromName,
    this.toName,
    this.route,
  });

  /// Kept from [logic]'s ride, its vehicle part only (the walks either side
  /// left out); [verdict] decides whether the path goes too. [endedAt]
  /// stands in when the ride had no fixes. The features are the whole
  /// ride's: what the logic saw when it asked.
  factory RideRecord.fromLogic(
    BusLogic logic, {
    required String id,
    required RideVerdict verdict,
    required DateTime endedAt,
    String? guideTo,
    RouteTag? route,
  }) {
    final keepPath = verdict != RideVerdict.notBus;
    final ride = logic.ride;
    final ended = ride.endedAt ?? endedAt;
    return RideRecord(
      id: id,
      startedAt: ride.startedAt ?? ended,
      endedAt: ended,
      verdict: verdict,
      distanceM: ride.distance.round(),
      path: keepPath
          ? List.unmodifiable(ride.path.take(maxPath).map(_round))
          : const [],
      halts: keepPath
          ? List.unmodifiable(
              ride.halts
                  .take(maxHalts)
                  .map((h) => Halt(_round(h.point), h.seconds)),
            )
          : const [],
      features: logic.features,
      guideTo: guideTo,
      route: keepPath ? route : null,
    );
  }

  /// As stored: five decimals, about a metre.
  static GeoPoint _round(GeoPoint p) =>
      GeoPoint((p.lat * 1e5).round() / 1e5, (p.lng * 1e5).round() / 1e5);

  /// Within the rules' sizes (firebase/firestore.rules, rides).
  static const maxPath = 1500;
  static const maxHalts = 350;

  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final RideVerdict verdict;
  final int distanceM;
  final List<GeoPoint> path;
  final List<Halt> halts;
  final Map<String, num> features;

  /// The stop a guide took the rider to, when one ran.
  final String? guideTo;

  /// Where the ride started and ended (a saved place or the area), once
  /// looked up (RideNamer).
  final String? fromName;
  final String? toName;

  /// The bus it was, as tagged (docs/PLAN.md, Which bus).
  final RouteTag? route;

  /// Still to be named: it has a path, and a name is missing.
  bool get unnamed => path.isNotEmpty && (fromName == null || toName == null);

  /// Relabelled; marked Not a bus, it loses its path, halts, names and
  /// its bus.
  RideRecord withVerdict(RideVerdict verdict) {
    final notBus = verdict == RideVerdict.notBus;
    return RideRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt,
      verdict: verdict,
      distanceM: distanceM,
      path: notBus ? const [] : path,
      halts: notBus ? const [] : halts,
      features: features,
      guideTo: guideTo,
      fromName: notBus ? null : fromName,
      toName: notBus ? null : toName,
      route: notBus ? null : route,
    );
  }

  /// Tagged with the bus it was, or untagged.
  RideRecord withRoute(RouteTag? route) => RideRecord(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    verdict: verdict,
    distanceM: distanceM,
    path: path,
    halts: halts,
    features: features,
    guideTo: guideTo,
    fromName: fromName,
    toName: toName,
    route: route,
  );

  RideRecord withNames({String? from, String? to}) => RideRecord(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    verdict: verdict,
    distanceM: distanceM,
    path: path,
    halts: halts,
    features: features,
    guideTo: guideTo,
    fromName: from ?? fromName,
    toName: to ?? toName,
    route: route,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.microsecondsSinceEpoch,
    'endedAt': endedAt.microsecondsSinceEpoch,
    'verdict': verdict.code,
    'distanceM': distanceM,
    'path': path.isEmpty ? null : encodePolyline(path),
    'halts': halts.isEmpty ? null : encodeHalts(halts),
    'features': features,
    'guideTo': guideTo,
    'fromName': fromName,
    'toName': toName,
    'route': route?.toJson(),
  };

  static RideRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final started = json['startedAt'];
    final ended = json['endedAt'];
    final distance = json['distanceM'];
    if (id is! String || started is! int || ended is! int || distance is! num) {
      return null;
    }
    final features = json['features'];
    return RideRecord(
      id: id,
      startedAt: DateTime.fromMicrosecondsSinceEpoch(started, isUtc: true),
      endedAt: DateTime.fromMicrosecondsSinceEpoch(ended, isUtc: true),
      verdict: RideVerdict.of(json['verdict']),
      distanceM: distance.round(),
      path: _decode(json['path'], decodePolyline),
      halts: _decode(json['halts'], decodeHalts),
      features: {
        if (features is Map)
          for (final MapEntry(:key, :value) in features.entries)
            if (key is String && value is num) key: value,
      },
      guideTo: _text(json['guideTo']),
      fromName: _text(json['fromName']),
      toName: _text(json['toName']),
      route: RouteTag.fromJson(json['route']),
    );
  }

  static String? _text(Object? value) => value is String ? value : null;

  static List<T> _decode<T>(Object? text, List<T> Function(String) decode) {
    if (text is! String || text.isEmpty) return const [];
    try {
      return decode(text);
    } on FormatException {
      return const [];
    }
  }

  @override
  List<Object?> get props => [
    id,
    startedAt,
    endedAt,
    verdict,
    distanceM,
    path,
    halts.map((h) => '${h.point.lat},${h.point.lng},${h.seconds}').toList(),
    features,
    guideTo,
    fromName,
    toName,
    route,
  ];
}

/// Halts as "lat,lng,seconds;..." with five decimals (about a metre).
String encodeHalts(Iterable<Halt> halts) => [
  for (final h in halts)
    '${h.point.lat.toStringAsFixed(5)},${h.point.lng.toStringAsFixed(5)},${h.seconds}',
].join(';');

List<Halt> decodeHalts(String text) => [
  for (final part in text.split(';'))
    if (part.split(',') case [final lat, final lng, final seconds])
      Halt(GeoPoint(double.parse(lat), double.parse(lng)), int.parse(seconds)),
];
