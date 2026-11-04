import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/ride/bus_logic.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// What a ride's map shows. Swappable like the home map ([RideMapBuilder]),
/// so widget tests run without the native view.
class RideMapProps {
  const RideMapProps({
    required this.path,
    required this.halts,
    required this.dark,
  });

  final List<GeoPoint> path;
  final List<Halt> halts;
  final bool dark;
}

typedef RideMapBuilder = Widget Function(RideMapProps props);

Widget boardRideMap(RideMapProps props) => RideMap(props: props);

/// One ride on the Board map (docs/PLAN.md, Rides page): the path in amber,
/// the halts as small dots, the start ringed and the end filled, framed to
/// fit.
class RideMap extends StatefulWidget {
  const RideMap({super.key, required this.props});

  final RideMapProps props;

  @override
  State<RideMap> createState() => _RideMapState();
}

class _RideMapState extends State<RideMap> {
  static const _amber = '#FFB020';
  static const _board = '#18241F';

  MapLibreMapController? _controller;

  Future<void> _draw() async {
    final controller = _controller;
    final path = widget.props.path;
    if (controller == null || path.isEmpty || !mounted) return;
    await controller.addLine(
      LineOptions(
        geometry: [for (final point in path) _latLng(point)],
        lineColor: _amber,
        lineWidth: 5,
        lineOpacity: 0.95,
        lineJoin: 'round',
      ),
    );
    await controller.addCircles([
      for (final halt in widget.props.halts)
        CircleOptions(
          geometry: _latLng(halt.point),
          circleRadius: 4,
          circleColor: _board,
          circleStrokeColor: _amber,
          circleStrokeWidth: 2,
        ),
      CircleOptions(
        geometry: _latLng(path.first),
        circleRadius: 7,
        circleColor: _board,
        circleStrokeColor: _amber,
        circleStrokeWidth: 3,
      ),
      CircleOptions(
        geometry: _latLng(path.last),
        circleRadius: 8,
        circleColor: _amber,
        circleStrokeColor: _board,
        circleStrokeWidth: 2,
      ),
    ]);
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        _bounds(path),
        left: 40,
        top: 40,
        right: 40,
        bottom: 40,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final path = props.path;
    return MapLibreMap(
      styleString: props.dark
          ? 'assets/map/board_dark.json'
          : 'assets/map/board_light.json',
      foregroundLoadColor: props.dark
          ? const Color(0xFF131D19)
          : const Color(0xFFECEFEA),
      initialCameraPosition: CameraPosition(
        target: _latLng(path.isEmpty ? colombo : path[path.length ~/ 2]),
        zoom: 13,
      ),
      onMapCreated: (controller) => _controller = controller,
      // A new style (light or dark) starts bare: draw again on each.
      onStyleLoadedCallback: () => unawaited(_draw()),
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      attributionButtonMargins: const Point(12, 12),
    );
  }
}

LatLng _latLng(GeoPoint point) => LatLng(point.lat, point.lng);

LatLngBounds _bounds(List<GeoPoint> path) {
  var south = path.first.lat;
  var north = south;
  var west = path.first.lng;
  var east = west;
  for (final point in path) {
    south = math.min(south, point.lat);
    north = math.max(north, point.lat);
    west = math.min(west, point.lng);
    east = math.max(east, point.lng);
  }
  return LatLngBounds(
    southwest: LatLng(south, west),
    northeast: LatLng(north, east),
  );
}
