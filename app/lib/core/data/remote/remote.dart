import 'package:cloud_firestore/cloud_firestore.dart';

/// One document as the server has it. Times are microseconds since the epoch.
class RemoteDoc {
  const RemoteDoc(this.id, this.data, this.updatedAt);

  final String id;
  final Map<String, Object?> data;
  final int updatedAt;
}

/// Firestore, as the sync engine needs it. Tests use an in-memory fake.
abstract interface class Remote {
  /// Documents in [collection] that the server changed after [after]: first
  /// each time the server answers, all of them. Only the server's word, never
  /// the cache's.
  Stream<List<RemoteDoc>> changes(String collection, int after);

  /// Writes [data] to [path] with `updatedAt` set to the server's time.
  /// Documents that can be removed pass [deleted], which writes `deletedAt`
  /// (the server's time, or null); others leave it out. Completes once the
  /// server has it.
  Future<void> put(String path, Map<String, Object?> data, {bool? deleted});
}

class FirestoreRemote implements Remote {
  FirestoreRemote([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Stream<List<RemoteDoc>> changes(String collection, int after) => _db
      .collection(collection)
      .where(
        'updatedAt',
        isGreaterThan: Timestamp.fromMicrosecondsSinceEpoch(after),
      )
      // With metadata changes, the server's answer comes even when it only
      // confirms what the cache already had.
      .snapshots(includeMetadataChanges: true)
      .where((snapshot) => !snapshot.metadata.isFromCache)
      .map(
        (snapshot) => [
          // All of them, not the changes: those count from the cache's answer,
          // which is skipped, so a document the cache already had would never
          // come through (a rebuilt local database stayed empty).
          for (final doc in snapshot.docs) ?_doc(doc),
        ],
      );

  RemoteDoc? _doc(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    final updatedAt = data?['updatedAt'];
    if (data == null ||
        updatedAt is! Timestamp ||
        snapshot.metadata.hasPendingWrites) {
      return null;
    }
    return RemoteDoc(snapshot.id, {
      for (final MapEntry(:key, :value) in data.entries)
        key: value is Timestamp ? value.microsecondsSinceEpoch : value,
    }, updatedAt.microsecondsSinceEpoch);
  }

  @override
  Future<void> put(String path, Map<String, Object?> data, {bool? deleted}) =>
      _db.doc(path).set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
        if (deleted != null)
          'deletedAt': deleted ? FieldValue.serverTimestamp() : null,
      });
}
