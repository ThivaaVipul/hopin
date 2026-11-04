import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';

enum PlaceKind { home, work, uni, other }

/// A place's names from OpenStreetMap, where it has them.
class PlaceNames extends Equatable {
  const PlaceNames({this.en, this.ta, this.si});

  final String? en;
  final String? ta;

  /// As on the bus board.
  final String? si;

  /// The name to show in the app's language, falling back to the other.
  String? inLanguage(String languageCode) =>
      languageCode == 'ta' ? (ta ?? en) : (en ?? ta);

  bool get isEmpty => en == null && ta == null && si == null;

  @override
  List<Object?> get props => [en, ta, si];
}

/// A place the rider saved, with their own name for it.
class SavedPlace extends Equatable {
  const SavedPlace({
    required this.id,
    required this.name,
    required this.kind,
    required this.point,
    this.names = const PlaceNames(),
    this.shareRides = false,
  });

  final String id;
  final String name;
  final PlaceKind kind;
  final GeoPoint point;
  final PlaceNames names;

  /// A guide here shares the ride by itself (docs/PLAN.md, Sharing and stops).
  final bool shareRides;

  SavedPlace copyWith({String? name, PlaceKind? kind, bool? shareRides}) =>
      SavedPlace(
        id: id,
        name: name ?? this.name,
        kind: kind ?? this.kind,
        point: point,
        names: names,
        shareRides: shareRides ?? this.shareRides,
      );

  @override
  List<Object?> get props => [id, name, kind, point, names, shareRides];
}

/// Somewhere the rider might go: a search result, a dropped pin or a saved place.
class Destination extends Equatable {
  const Destination({
    required this.point,
    this.names = const PlaceNames(),
    this.area,
    this.saved,
  });

  factory Destination.fromSaved(SavedPlace place) =>
      Destination(point: place.point, names: place.names, saved: place);

  final GeoPoint point;
  final PlaceNames names;

  /// The suburb and town, when known.
  final String? area;
  final SavedPlace? saved;

  Destination withSaved(SavedPlace? place) =>
      Destination(point: point, names: names, area: area, saved: place);

  @override
  List<Object?> get props => [point, names, area, saved];
}
