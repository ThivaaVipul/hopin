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
/// guide), until the rider changes them in Settings.
const defaultStages = [
  GuideStage(1500, AlertPattern.gentleDoubleTap),
  GuideStage(400, AlertPattern.strongLongBuzz),
];

/// The distances a stage can use (docs/PLAN.md, Settings and updates).
const stageDistances = [3000, 2000, 1500, 1000, 700, 500, 400, 300, 150];

/// Most stages a guide has.
const maxStages = 3;

/// [stages] outermost first, one per distance, at most [maxStages].
List<GuideStage> tidyStages(Iterable<GuideStage> stages) {
  final byDistance = <int, GuideStage>{
    for (final stage in stages)
      if (stageDistances.contains(stage.metres)) stage.metres: stage,
  };
  final sorted = byDistance.values.toList()
    ..sort((a, b) => b.metres.compareTo(a.metres));
  return sorted.take(maxStages).toList();
}

/// Stages as saved (a JSON list); [defaultStages] when there are none.
List<GuideStage> stagesFromJson(Object? json) {
  final stages = tidyStages([
    if (json is List)
      for (final stage in json) ?GuideStage.fromJson(stage),
  ]);
  return stages.isEmpty ? defaultStages : stages;
}

/// A guide to one stop, as the ride service gets it.
class GuideRide extends Equatable {
  const GuideRide({
    required this.to,
    required this.title,
    this.names = const PlaceNames(),
    this.area,
    this.stages = defaultStages,
    this.language = 'en',
    this.share = false,
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

  /// Shared from the start: the stop is a place the rider shares rides to
  /// (docs/PLAN.md, Sharing and stops).
  final bool share;

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
    'share': share,
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
      share: json['share'] == true,
    );
  }

  @override
  List<Object?> get props => [to, title, names, area, stages, language, share];
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
    this.asking = false,
  });

  /// Straight-line distance to the stop.
  final double metres;

  /// From 0 at the start to 1 at the stop.
  final double progress;

  /// Time to the stop at your recent speed; null while you are still.
  final Duration? left;
  final GuidePhase phase;
  final GeoPoint? at;

  /// Waiting for an answer to "Still going to (stop)?".
  final bool asking;

  Map<String, Object?> toJson() => {
    'metres': metres,
    'progress': progress,
    'left': left?.inSeconds,
    'phase': phase.name,
    'lat': at?.lat,
    'lng': at?.lng,
    'asking': asking,
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
      asking: json['asking'] == true,
    );
  }

  @override
  List<Object?> get props => [metres, progress, left, phase, at, asking];
}
