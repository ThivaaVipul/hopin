import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/bus_logic.dart';

/// Where a stop comes from (docs/PLAN.md, Sharing and stops).
enum StopSource { osm, learned }

/// A bus stop on the map: one of OpenStreetMap's, or one learned from where
/// the riders' buses keep halting.
class Stop extends Equatable {
  const Stop({
    required this.id,
    required this.point,
    required this.source,
    this.names = const PlaceNames(),
    this.rides = 0,
  });

  /// `osm:` and the node, or `learned:` and the spot to four decimals
  /// (about 10 m).
  final String id;
  final GeoPoint point;
  final StopSource source;
  final PlaceNames names;

  /// How many of the riders' bus rides halted here.
  final int rides;

  bool get learned => source == StopSource.learned;

  Stop withNames(PlaceNames names) =>
      Stop(id: id, point: point, source: source, names: names, rides: rides);

  @override
  List<Object?> get props => [id, point, source, names, rides];
}

/// One of OpenStreetMap's bus stops.
class OsmStop extends Equatable {
  const OsmStop({
    required this.id,
    required this.point,
    this.names = const PlaceNames(),
  });

  final int id;
  final GeoPoint point;
  final PlaceNames names;

  @override
  List<Object?> get props => [id, point, names];
}

/// A bus ride's halts, from the pool both riders share.
class RideHalts extends Equatable {
  const RideHalts(this.rideId, this.halts);

  final String rideId;
  final List<Halt> halts;

  @override
  List<Object?> get props => [rideId, halts.length];
}

/// A rider's rename or removal of a learned stop, kept at its spot.
class StopNote extends Equatable {
  const StopNote({
    required this.id,
    required this.point,
    required this.at,
    this.name,
    this.removed = false,
  });

  final String id;
  final GeoPoint point;
  final DateTime at;
  final String? name;
  final bool removed;

  @override
  List<Object?> get props => [id, point, at, name, removed];
}

/// Works out the stops from the pooled halts (docs/PLAN.md, Sharing and
/// stops): a halt of 10 to 90 s within [near] of an OSM stop counts towards
/// it; elsewhere, halts from at least [minRides] different rides within
/// [near] of each other make a learned stop. The latest note within [near]
/// of a learned stop renames it, or removes it for good.
class StopFinder {
  const StopFinder();

  static const near = 30.0;
  static const minRides = 2;
  static const shortestHalt = 10;
  static const longestHalt = 90;

  List<Stop> find({
    required List<RideHalts> rides,
    List<OsmStop> osm = const [],
    List<StopNote> notes = const [],
  }) {
    final osmRides = <int, Set<String>>{};
    final loose = <(String, GeoPoint)>[];
    for (final ride in rides) {
      for (final halt in ride.halts) {
        if (halt.seconds < shortestHalt || halt.seconds > longestHalt) continue;
        final stop = _nearest(osm, halt.point);
        if (stop != null) {
          (osmRides[stop.id] ??= {}).add(ride.rideId);
        } else {
          loose.add((ride.rideId, halt.point));
        }
      }
    }

    // The same halts make the same stops in any order.
    loose.sort((a, b) {
      final byLat = a.$2.lat.compareTo(b.$2.lat);
      return byLat != 0 ? byLat : a.$2.lng.compareTo(b.$2.lng);
    });
    final clusters = <_Cluster>[];
    for (final (ride, point) in loose) {
      _Cluster? best;
      var bestAway = near;
      for (final cluster in clusters) {
        final away = cluster.centre.distanceTo(point);
        if (away <= bestAway) {
          best = cluster;
          bestAway = away;
        }
      }
      (best ?? (clusters..add(_Cluster())).last).add(ride, point);
    }

    final latest = [...notes]..sort((a, b) => b.at.compareTo(a.at));
    return [
      for (final stop in osm)
        Stop(
          id: 'osm:${stop.id}',
          point: stop.point,
          source: StopSource.osm,
          names: stop.names,
          rides: osmRides[stop.id]?.length ?? 0,
        ),
      for (final cluster in clusters)
        if (cluster.rides.length >= minRides) ?_learned(cluster, latest),
    ];
  }

  Stop? _learned(_Cluster cluster, List<StopNote> latestFirst) {
    final centre = cluster.centre;
    final note = latestFirst
        .where((note) => note.point.distanceTo(centre) <= near)
        .firstOrNull;
    if (note?.removed ?? false) return null;
    return Stop(
      id:
          'learned:${centre.lat.toStringAsFixed(4)},'
          '${centre.lng.toStringAsFixed(4)}',
      point: centre,
      source: StopSource.learned,
      names: PlaceNames(en: note?.name),
      rides: cluster.rides.length,
    );
  }

  static OsmStop? _nearest(List<OsmStop> stops, GeoPoint point) {
    OsmStop? best;
    var bestAway = near;
    for (final stop in stops) {
      final away = stop.point.distanceTo(point);
      if (away <= bestAway) {
        best = stop;
        bestAway = away;
      }
    }
    return best;
  }
}

class _Cluster {
  final rides = <String>{};
  var _lat = 0.0;
  var _lng = 0.0;
  var _count = 0;

  GeoPoint get centre => GeoPoint(_lat / _count, _lng / _count);

  void add(String ride, GeoPoint point) {
    rides.add(ride);
    _lat += point.lat;
    _lng += point.lng;
    _count++;
  }
}
