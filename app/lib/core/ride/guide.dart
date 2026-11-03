import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/places/place.dart';
import 'package:hopin/core/ride/patterns.dart';

/// One alert: [pattern] once you are within [metres] of your stop.
class GuideStage extends Equatable {
  const GuideStage(this.metres, this.pattern);

  final int metres;
  final AlertPattern pattern;

  Map<String, Object?> toJson() => {'metres': metres, 'pattern': pattern.name};

  static GuideStage? fromJson(Object? json) {
    if (json is! Map) return null;
    final metres = json['metres'];
    final pattern = AlertPattern.values
        .where((p) => p.name == json['pattern'])
        .firstOrNull;
    if (metres is! int || pattern == null) return null;
    return GuideStage(metres, pattern);
  }

  @override
  List<Object?> get props => [metres, pattern];
}

/// "Get ready" at 1.5 km and "Get off next" at 400 m (docs/PLAN.md, The
/// guide). Settings edits them in M1a4.
const defaultStages = [
  GuideStage(1500, AlertPattern.gentleDoubleTap),
  GuideStage(400, AlertPattern.strongLongBuzz),
];

/// A guide to one stop, as the ride service gets it.
class GuideRide extends Equatable {
  const GuideRide({
    required this.to,
    required this.title,
    this.names = const PlaceNames(),
    this.area,
    this.stages = defaultStages,
    this.language = 'en',
  });

  final GeoPoint to;

  /// The stop's name in the app's language, for the notifications.
  final String title;
  final PlaceNames names;
  final String? area;

  /// Outermost first; the last one is "Get off next".
  final List<GuideStage> stages;

  /// The app's language, for the notifications.
  final String language;

  Destination get destination =>
      Destination(point: to, names: names, area: area);

  Map<String, Object?> toJson() => {
    'lat': to.lat,
    'lng': to.lng,
    'title': title,
    'en': names.en,
    'ta': names.ta,
    'si': names.si,
    'area': area,
    'stages': [for (final stage in stages) stage.toJson()],
    'language': language,
  };

  static GuideRide? fromJson(Object? json) {
    if (json is! Map) return null;
    final lat = json['lat'];
    final lng = json['lng'];
    final title = json['title'];
    final stages = [
      if (json['stages'] case final List<Object?> list)
        for (final stage in list) ?GuideStage.fromJson(stage),
    ];
    if (lat is! num || lng is! num || title is! String || stages.isEmpty) {
      return null;
    }
    String? text(String key) =>
        json[key] is String ? json[key] as String : null;
    return GuideRide(
      to: GeoPoint(lat.toDouble(), lng.toDouble()),
      title: title,
      names: PlaceNames(en: text('en'), ta: text('ta'), si: text('si')),
      area: text('area'),
      stages: stages,
      language: text('language') ?? 'en',
    );
  }

  @override
  List<Object?> get props => [to, title, names, area, stages, language];
}

/// Whole minutes for the board, never less than one.
int wholeMinutes(Duration left) => math.max(1, (left.inSeconds / 60).round());

enum GuidePhase {
  riding,

  /// The last stage has fired: the board turns amber.
  getOff,

  /// You went past your stop; the guide goes on so you can head back.
  passed,
}

/// Where a guide stands after a fix.
class GuideStatus extends Equatable {
  const GuideStatus({
    required this.metres,
    required this.progress,
    this.left,
    this.phase = GuidePhase.riding,
    this.at,
  });

  /// Straight-line distance to the stop.
  final double metres;

  /// From 0 at the start to 1 at the stop.
  final double progress;

  /// Time to the stop at your recent speed; null while you are still.
  final Duration? left;
  final GuidePhase phase;
  final GeoPoint? at;

  Map<String, Object?> toJson() => {
    'metres': metres,
    'progress': progress,
    'left': left?.inSeconds,
    'phase': phase.name,
    'lat': at?.lat,
    'lng': at?.lng,
  };

  static GuideStatus? fromJson(Object? json) {
    if (json is! Map) return null;
    final metres = json['metres'];
    final progress = json['progress'];
    if (metres is! num || progress is! num) return null;
    final left = json['left'];
    final lat = json['lat'];
    final lng = json['lng'];
    return GuideStatus(
      metres: metres.toDouble(),
      progress: progress.toDouble(),
      left: left is int ? Duration(seconds: left) : null,
      phase:
          GuidePhase.values.where((p) => p.name == json['phase']).firstOrNull ??
          GuidePhase.riding,
      at: lat is num && lng is num
          ? GeoPoint(lat.toDouble(), lng.toDouble())
          : null,
    );
  }

  @override
  List<Object?> get props => [metres, progress, left, phase, at];
}
