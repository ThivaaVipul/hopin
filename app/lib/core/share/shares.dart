import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import 'package:hopin/core/geo/geo.dart';
import 'package:hopin/core/share/share.dart';

/// Open shares, for the other rider's Home (docs/PLAN.md, Sharing and stops).
abstract interface class Shares {
  /// Every open share, as they change; Home leaves out the rider's own.
  Stream<List<LiveShare>> watchOpen();

  /// Ends [uid]'s shares still open but no longer written: the ride service
  /// stopped without closing them (killed by the phone, say).
  Future<void> closeLeftOpen(String uid);
}

/// The ride service's side: it writes its rider's share.
abstract interface class ShareWriter {
  Future<void> open(
    String id, {
    required String uid,
    required DateTime startedAt,
    GeoPoint? at,
    ShareGoal? goal,
  });

  Future<void> move(String id, {required GeoPoint at, ShareGoal? goal});

  /// Ends it: the share is deleted, so nothing of it is kept; an open page
  /// then says the ride ended.
  Future<void> close(String id);
}

/// The `shares` collection (firebase/firestore.rules): anyone reads one share
/// by its id; riders list the open ones; only the sharing rider writes.
class FirestoreShares implements Shares, ShareWriter {
  FirestoreShares([FirebaseFirestore? firestore])
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _shares =>
      _db.collection('shares');

  Query<Map<String, dynamic>> get _open =>
      _shares.where('endedAt', isNull: true);

  @override
  Stream<List<LiveShare>> watchOpen() => _open.snapshots().map(
    (snapshot) => [
      for (final doc in snapshot.docs) ?liveShareFrom(doc.id, doc.data()),
    ],
  );

  @override
  Future<void> closeLeftOpen(String uid) async {
    final open = await _open.where('uid', isEqualTo: uid).get();
    for (final doc in open.docs) {
      unawaited(close(doc.id).catchError((Object _) {}));
    }
  }

  @override
  Future<void> open(
    String id, {
    required String uid,
    required DateTime startedAt,
    GeoPoint? at,
    ShareGoal? goal,
  }) => _shares.doc(id).set({
    'uid': uid,
    'lat': at?.lat,
    'lng': at?.lng,
    ..._goal(goal),
    'startedAt': Timestamp.fromDate(startedAt),
    'endedAt': null,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> move(String id, {required GeoPoint at, ShareGoal? goal}) =>
      _shares.doc(id).update({
        'lat': at.lat,
        'lng': at.lng,
        ..._goal(goal),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  @override
  Future<void> close(String id) => _shares.doc(id).delete();

  static Map<String, Object?> _goal(ShareGoal? goal) => {
    'toName': goal?.name,
    'toTa': goal?.nameTa,
    'toLat': goal?.point.lat,
    'toLng': goal?.point.lng,
    'leftMin': goal?.minutesLeft,
    'metresLeft': goal?.metresLeft,
  };
}

/// A share document as Home reads it; null when it isn't one.
LiveShare? liveShareFrom(String id, Map<String, dynamic> data) {
  final uid = data['uid'];
  if (uid is! String) return null;
  GeoPoint? point(Object? lat, Object? lng) => lat is num && lng is num
      ? GeoPoint(lat.toDouble(), lng.toDouble())
      : null;
  final to = point(data['toLat'], data['toLng']);
  final name = data['toName'];
  final updated = data['updatedAt'];
  return LiveShare(
    id: id,
    uid: uid,
    at: point(data['lat'], data['lng']),
    goal: to != null && name is String
        ? ShareGoal(
            name: name,
            nameTa: data['toTa'] is String ? data['toTa'] as String : null,
            point: to,
            minutesLeft: (data['leftMin'] as num?)?.toInt(),
            metresLeft: (data['metresLeft'] as num?)?.toInt(),
          )
        : null,
    updatedAt: updated is Timestamp ? updated.toDate() : null,
  );
}
