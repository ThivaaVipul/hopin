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
  /// all of them, then each change. Only the server's word, never the cache's.
  Stream<List<RemoteDoc>> changes(String collection, int after);

  /// Writes [data] to [path] with `updatedAt` (and `deletedAt` when [deleted])
  /// set to the server's time. Completes once the server has it.
  Future<void> put(
    String path,
    Map<String, Object?> data, {
    bool deleted = false,
  });
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
      .snapshots()
      .where((snapshot) => !snapshot.metadata.isFromCache)
      .map(
        (snapshot) => [
          for (final change in snapshot.docChanges) ?_doc(change.doc),
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
  Future<void> put(
    String path,
    Map<String, Object?> data, {
    bool deleted = false,
  }) => _db.doc(path).set({
    ...data,
    'updatedAt': FieldValue.serverTimestamp(),
    'deletedAt': deleted ? FieldValue.serverTimestamp() : null,
  });
}
