import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/stops.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

/// Moves the map's camera from outside the map widget.
class MapCamera {
  void Function(GeoPoint point, double zoom)? _fly;
  void Function(GeoPoint a, GeoPoint b, EdgeInsets padding)? _fit;

  void flyTo(GeoPoint point, {double zoom = 15}) => _fly?.call(point, zoom);

  /// Shows both points, clear of [padding] (logical pixels) at the edges.
  void fit(GeoPoint a, GeoPoint b, {EdgeInsets padding = EdgeInsets.zero}) =>
      _fit?.call(a, b, padding);
}

/// What the home map shows. The map itself is swappable ([MapBuilder]), so
/// widget tests run without the native MapLibre view.
class MapProps {
  const MapProps({
    required this.me,
    required this.places,
    required this.destination,
    required this.camera,
    required this.onLongPress,
    required this.dark,
    this.watched,
    this.watchedGoal,
    this.stops = const [],
    this.onStopTap,
    this.onCameraIdle,
  });

  final GeoPoint? me;
  final List<SavedPlace> places;
  final Destination? destination;
  final MapCamera camera;
  final void Function(GeoPoint point) onLongPress;
  final bool dark;

  /// The other rider's shared position while watched, and their stop.
  final GeoPoint? watched;
  final GeoPoint? watchedGoal;

  /// The bus stops in view, as small dots; a tap gives the stop's id.
  final List<Stop> stops;
  final void Function(String id)? onStopTap;

  /// The map settled: its south-west and north-east corners, and its zoom.
  final void Function(GeoPoint southWest, GeoPoint northEast, double zoom)?
  onCameraIdle;
}

typedef MapBuilder = Widget Function(MapProps props);

Widget boardMap(MapProps props) => BoardMap(props: props);

/// Call once before the first map is built (main.dart). The map renders into a
/// TextureView, which Flutter composites like any widget: no flicker when a
/// sheet or panel over it closes, and smoother dragging than the default
/// SurfaceView, which Flutter can only embed through a virtual display.
void prepareBoardMap() => MapLibreMap.useHybridComposition = true;

/// MapLibre with OpenFreeMap tiles in the Board style (docs/ARCHITECTURE.md,
/// Map). Markers are the map's own circles, so they move with it smoothly.
class BoardMap extends StatefulWidget {
  const BoardMap({super.key, required this.props});

  final MapProps props;

  @override
  State<BoardMap> createState() => _BoardMapState();
}

class _BoardMapState extends State<BoardMap> {
  static const _amber = '#FFB020';
  static const _board = '#18241F';

  MapLibreMapController? _controller;
  bool _styled = false;

  /// One redraw at a time; a request during one makes it go round again.
  Future<void>? _drawing;
  bool _drawAgain = false;

  final _halo = _Marker(radius: 20, color: _amber, opacity: 0.2, stroke: 0);
  final _me = _Marker(radius: 7, color: _amber);
  final _destination = _Marker(radius: 9, color: _amber);
  final _them = _Marker(radius: 9, color: '#F4F1E8');
  final _theirGoal = _Marker(radius: 7, color: _amber, stroke: 2);
  List<Circle> _places = const [];
  List<SavedPlace>? _drawnPlaces;

  /// The stops' source and layer: every stop at once, drawn by the map
  /// itself from street level in (one call per change, however many).
  static const _stopSource = 'hopin-stops';
  static const _stopLayer = 'hopin-stops-dots';

  /// Stop dots show from this zoom in (street level).
  static const stopsFrom = 15.0;
  bool _stopsAdded = false;
  List<Stop>? _drawnStops;

  @override
  void initState() {
    super.initState();
    _bindCamera();
  }

  @override
  void didUpdateWidget(BoardMap old) {
    super.didUpdateWidget(old);
    _bindCamera();
    if (old.props.dark != widget.props.dark) {
      // A new style drops the markers; they come back once it has loaded.
      _styled = false;
      for (final marker in [_halo, _me, _destination, _them, _theirGoal]) {
        marker.forget();
      }
      _places = const [];
      _drawnPlaces = null;
      _stopsAdded = false;
      _drawnStops = null;
    } else {
      _redraw();
    }
  }

  void _bindCamera() {
    final camera = widget.props.camera;
    camera._fly = (point, zoom) => unawaited(
      _controller?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(point.lat, point.lng), zoom),
        duration: const Duration(milliseconds: 700),
      ),
    );
    camera._fit = (a, b, padding) => unawaited(
      _controller?.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(math.min(a.lat, b.lat), math.min(a.lng, b.lng)),
            northeast: LatLng(math.max(a.lat, b.lat), math.max(a.lng, b.lng)),
          ),
          left: padding.left,
          top: padding.top,
          right: padding.right,
          bottom: padding.bottom,
        ),
        duration: const Duration(milliseconds: 700),
      ),
    );
  }

  void _redraw() {
    if (_drawing != null) {
      _drawAgain = true;
      return;
    }
    _drawing = _drawUntilSettled().whenComplete(() => _drawing = null);
  }

  Future<void> _drawUntilSettled() async {
    do {
      _drawAgain = false;
      await _draw();
    } while (_drawAgain && mounted);
  }

  Future<void> _draw() async {
    final controller = _controller;
    if (controller == null || !_styled) return;
    final props = widget.props;

    if (!identical(_drawnPlaces, props.places)) {
      _drawnPlaces = props.places;
      if (_places.isNotEmpty) await controller.removeCircles(_places);
      _places = [
        for (final place in props.places)
          await controller.addCircle(
            CircleOptions(
              geometry: _latLng(place.point),
              circleRadius: 6,
              circleColor: _board,
              circleStrokeColor: _amber,
              circleStrokeWidth: 2,
            ),
          ),
      ];
    }
    await _drawStops(controller, props.stops);
    await _destination.show(controller, props.destination?.point);
    await _theirGoal.show(controller, props.watchedGoal);
    await _them.show(controller, props.watched);
    await _halo.show(controller, props.me);
    await _me.show(controller, props.me);
  }

  /// All the stops as one GeoJSON source and one circle layer, under the
  /// markers; a change of stops is one update, not a call per dot.
  Future<void> _drawStops(
    MapLibreMapController controller,
    List<Stop> stops,
  ) async {
    if (identical(stops, _drawnStops)) return;
    _drawnStops = stops;
    final data = _stopFeatures(stops);
    if (_stopsAdded) {
      await controller.setGeoJsonSource(_stopSource, data);
      return;
    }
    _stopsAdded = true;
    await controller.addGeoJsonSource(_stopSource, data, promoteId: 'sid');
    await controller.addCircleLayer(
      _stopSource,
      _stopLayer,
      const CircleLayerProperties(
        circleRadius: 5,
        circleColor: '#F4F1E8',
        circleStrokeWidth: 2,
        // Learned stops ringed in amber, OSM's in the board's green-black.
        circleStrokeColor: [
          'case',
          [
            '==',
            ['get', 'learned'],
            true,
          ],
          _amber,
          _board,
        ],
      ),
      belowLayerId: controller.circleManager?.layerIds.firstOrNull,
      minzoom: stopsFrom,
    );
  }

  static Map<String, dynamic> _stopFeatures(List<Stop> stops) => {
    'type': 'FeatureCollection',
    'features': [
      for (final stop in stops)
        {
          'type': 'Feature',
          'properties': {'sid': stop.id, 'learned': stop.learned},
          'geometry': {
            'type': 'Point',
            'coordinates': [stop.point.lng, stop.point.lat],
          },
        },
    ],
  };

  void _featureTapped(
    Point<double> point,
    LatLng at,
    String id,
    String layerId,
    Annotation? annotation,
  ) {
    if (layerId == _stopLayer) widget.props.onStopTap?.call(id);
  }

  Future<void> _idle() async {
    final controller = _controller;
    final zoom = controller?.cameraPosition?.zoom;
    if (controller == null || zoom == null || !mounted) return;
    final region = await controller.getVisibleRegion();
    widget.props.onCameraIdle?.call(
      GeoPoint(region.southwest.latitude, region.southwest.longitude),
      GeoPoint(region.northeast.latitude, region.northeast.longitude),
      zoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final start = props.me ?? props.destination?.point ?? colombo;
    return MapLibreMap(
      styleString: props.dark
          ? 'assets/map/board_dark.json'
          : 'assets/map/board_light.json',
      // The Board land colour while the style loads, never a white flash.
      foregroundLoadColor: props.dark
          ? const Color(0xFF131D19)
          : const Color(0xFFECEFEA),
      initialCameraPosition: CameraPosition(
        target: _latLng(start),
        zoom: props.me == null ? 12 : 15,
      ),
      onMapCreated: (controller) {
        _controller = controller;
        controller.onFeatureTapped.add(_featureTapped);
      },
      onStyleLoadedCallback: () {
        _styled = true;
        _redraw();
        unawaited(_idle());
      },
      trackCameraPosition: true,
      onCameraIdle: () => unawaited(_idle()),
      onMapLongClick: (Point<double> _, LatLng at) =>
          props.onLongPress(GeoPoint(at.latitude, at.longitude)),
      compassEnabled: false,
      rotateGesturesEnabled: false,
      tiltGesturesEnabled: false,
      attributionButtonPosition: AttributionButtonPosition.bottomLeft,
      attributionButtonMargins: const Point(12, 12),
    );
  }
}

LatLng _latLng(GeoPoint point) => LatLng(point.lat, point.lng);

/// One circle on the map that follows a point: added when the point appears,
/// moved only when it changes, removed when it goes.
class _Marker {
  _Marker({
    required this.radius,
    required this.color,
    this.opacity = 1,
    this.stroke = 3,
  });

  final double radius;
  final String color;
  final double opacity;
  final double stroke;
  Circle? _circle;
  GeoPoint? _at;

  void forget() {
    _circle = null;
    _at = null;
  }

  Future<void> show(MapLibreMapController controller, GeoPoint? point) async {
    if (point == _at) return;
    final circle = _circle;
    if (point == null) {
      if (circle != null) await controller.removeCircle(circle);
      _circle = null;
    } else if (circle != null) {
      await controller.updateCircle(
        circle,
        CircleOptions(geometry: _latLng(point)),
      );
    } else {
      _circle = await controller.addCircle(
        CircleOptions(
          geometry: _latLng(point),
          circleRadius: radius,
          circleColor: color,
          circleOpacity: opacity,
          circleStrokeColor: '#18241F',
          circleStrokeWidth: stroke,
        ),
      );
    }
    _at = point;
  }
}
