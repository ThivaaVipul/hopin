import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Point;

import 'package:flutter/material.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
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
  });

  final GeoPoint? me;
  final List<SavedPlace> places;
  final Destination? destination;
  final MapCamera camera;
  final void Function(GeoPoint point) onLongPress;
  final bool dark;
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
  List<Circle> _places = const [];
  List<SavedPlace>? _drawnPlaces;

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
      for (final marker in [_halo, _me, _destination]) {
        marker.forget();
      }
      _places = const [];
      _drawnPlaces = null;
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
    await _destination.show(controller, props.destination?.point);
    await _halo.show(controller, props.me);
    await _me.show(controller, props.me);
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
      onMapCreated: (controller) => _controller = controller,
      onStyleLoadedCallback: () {
        _styled = true;
        _redraw();
      },
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
