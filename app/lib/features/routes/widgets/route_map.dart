import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// What a route's map shows. Swappable like the ride map, so widget tests
/// run without the native view.
class RouteMapProps {
  const RouteMapProps({
    required this.roads,
    required this.guessed,
    required this.marks,
    required this.dark,
  });

  /// The mapped roads, drawn solid, and their guessed parts, dashed.
  final List<List<GeoPoint>> roads;
  final List<List<GeoPoint>> guessed;

  /// Where it starts (ringed) and ends (filled), and for a route without a
  /// road (NTC's) the towns it runs through between them (small rings).
  final List<GeoPoint> marks;
  final bool dark;
}

typedef RouteMapBuilder = Widget Function(RouteMapProps props);

Widget boardRouteMap(RouteMapProps props) => RouteMap(props: props);

/// One route on the Board map: its road in amber (guessed parts dashed) or
/// its towns, the start ringed and the end filled, framed to fit.
class RouteMap extends StatefulWidget {
  const RouteMap({super.key, required this.props});

  final RouteMapProps props;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  static const _amber = '#FFB020';
  static const _board = '#18241F';
  static const _source = 'hopin-route';

  MapLibreMapController? _controller;

  List<GeoPoint> get _everything => [
    ...widget.props.roads.expand((road) => road),
    ...widget.props.guessed.expand((part) => part),
    ...widget.props.marks,
  ];

  Future<void> _draw() async {
    final controller = _controller;
    final props = widget.props;
    final everything = _everything;
    if (controller == null || everything.isEmpty || !mounted) return;
    Map<String, Object?> line(List<GeoPoint> points, {required bool guessed}) =>
        {
          'type': 'Feature',
          'properties': {'guessed': guessed},
          'geometry': {
            'type': 'LineString',
            'coordinates': [
              for (final point in points) [point.lng, point.lat],
            ],
          },
        };
    await controller.addGeoJsonSource(_source, {
      'type': 'FeatureCollection',
      'features': [
        for (final road in props.roads)
          if (road.length > 1) line(road, guessed: false),
        for (final part in props.guessed)
          if (part.length > 1) line(part, guessed: true),
      ],
    });
    await controller.addLineLayer(
      _source,
      'hopin-route-line',
      const LineLayerProperties(
        lineColor: _amber,
        lineWidth: 5,
        lineOpacity: 0.9,
        lineCap: 'round',
        lineJoin: 'round',
      ),
      filter: [
        '==',
        ['get', 'guessed'],
        false,
      ],
    );
    await controller.addLineLayer(
      _source,
      'hopin-route-guess',
      const LineLayerProperties(
        lineColor: _amber,
        lineWidth: 4,
        lineOpacity: 0.75,
        lineDasharray: [1.2, 1.6],
      ),
      filter: [
        '==',
        ['get', 'guessed'],
        true,
      ],
    );
    final ends = props.marks;
    await controller.addCircles([
      for (final (i, town) in ends.indexed)
        i == ends.length - 1
            ? CircleOptions(
                geometry: _latLng(town),
                circleRadius: 8,
                circleColor: _amber,
                circleStrokeColor: _board,
                circleStrokeWidth: 2,
              )
            : CircleOptions(
                geometry: _latLng(town),
                circleRadius: i == 0 ? 7 : 5,
                circleColor: _board,
                circleStrokeColor: _amber,
                circleStrokeWidth: 3,
              ),
    ]);
    await controller.moveCamera(
      CameraUpdate.newLatLngBounds(
        _bounds(everything),
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
    final everything = _everything;
    return MapLibreMap(
      styleString: props.dark
          ? 'assets/map/board_dark.json'
          : 'assets/map/board_light.json',
      foregroundLoadColor: props.dark
          ? const Color(0xFF131D19)
          : const Color(0xFFECEFEA),
      initialCameraPosition: CameraPosition(
        target: _latLng(
          everything.isEmpty ? colombo : everything[everything.length ~/ 2],
        ),
        zoom: 11,
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

LatLngBounds _bounds(List<GeoPoint> points) {
  var south = points.first.lat;
  var north = south;
  var west = points.first.lng;
  var east = west;
  for (final point in points) {
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
