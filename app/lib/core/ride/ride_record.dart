import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:hopin/core/ride/polyline.dart';

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
/// not a bus keeps no path or halts.
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
  });

  /// Kept from [logic]'s ride; [verdict] decides whether the path goes too.
  factory RideRecord.fromLogic(
    BusLogic logic, {
    required String id,
    required RideVerdict verdict,
    required DateTime endedAt,
    String? guideTo,
  }) {
    final keepPath = verdict != RideVerdict.notBus;
    return RideRecord(
      id: id,
      startedAt: logic.startedAt ?? endedAt,
      endedAt: endedAt,
      verdict: verdict,
      distanceM: logic.distance.round(),
      path: keepPath
          ? List.unmodifiable(logic.path.take(maxPath).map(_round))
          : const [],
      halts: keepPath
          ? List.unmodifiable(
              logic.halts
                  .take(maxHalts)
                  .map((h) => Halt(_round(h.point), h.seconds)),
            )
          : const [],
      features: logic.features,
      guideTo: guideTo,
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

  RideRecord withVerdict(RideVerdict verdict) => RideRecord(
    id: id,
    startedAt: startedAt,
    endedAt: endedAt,
    verdict: verdict,
    distanceM: distanceM,
    path: verdict == RideVerdict.notBus ? const [] : path,
    halts: verdict == RideVerdict.notBus ? const [] : halts,
    features: features,
    guideTo: guideTo,
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
      guideTo: json['guideTo'] is String ? json['guideTo'] as String : null,
    );
  }

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
