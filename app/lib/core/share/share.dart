import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:hopin/core/geo/geo.dart';

/// Where shares are watched: the web page on Firebase Hosting
/// (firebase/hosting), at /r/ and the share's id.
const shareSite = 'https://hopin-riders.web.app';

String shareLink(String id) => '$shareSite/r/$id';

/// A new share's id: 20 letters and digits from a secure source, so a link
/// can't be guessed (the rules take 20 to 40).
String newShareId([Random? random]) {
  const chars =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  final source = random ?? Random.secure();
  return String.fromCharCodes(
    Iterable.generate(
      20,
      (_) => chars.codeUnitAt(source.nextInt(chars.length)),
    ),
  );
}

/// Where a guided ride is going, for its share; a noticed ride has none.
class ShareGoal extends Equatable {
  const ShareGoal({
    required this.name,
    required this.point,
    this.nameTa,
    this.minutesLeft,
    this.metresLeft,
  });

  /// The stop as the rider names it, and in Tamil where known.
  final String name;
  final String? nameTa;
  final GeoPoint point;
  final int? minutesLeft;
  final int? metresLeft;

  @override
  List<Object?> get props => [name, nameTa, point, minutesLeft, metresLeft];
}

/// When the ride service writes its share again (docs/PLAN.md, Sharing and
/// stops): about every 10 s while moving, once a minute while halted.
class SharePacer {
  static const moving = Duration(seconds: 10);
  static const halted = Duration(minutes: 1);

  /// Closer than this to the last written position counts as halted.
  static const movedMetres = 20.0;

  GeoPoint? _last;
  DateTime? _at;

  bool due(GeoPoint here, DateTime now) {
    final last = _last;
    final at = _at;
    if (last == null || at == null) return true;
    final gap = now.difference(at);
    if (gap >= halted) return true;
    return gap >= moving && last.distanceTo(here) >= movedMetres;
  }

  void sent(GeoPoint here, DateTime now) {
    _last = here;
    _at = now;
  }
}

/// Someone's open share, as the other rider's Home sees it.
class LiveShare extends Equatable {
  const LiveShare({
    required this.id,
    required this.uid,
    this.at,
    this.goal,
    this.updatedAt,
  });

  final String id;

  /// Whose share it is; Home leaves out the rider's own.
  final String uid;

  /// Null until the first position arrives.
  final GeoPoint? at;
  final ShareGoal? goal;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [id, uid, at, goal, updatedAt];
}
