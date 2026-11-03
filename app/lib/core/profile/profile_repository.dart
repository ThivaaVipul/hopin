import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hopin/core/auth/auth_repository.dart';

/// A rider's profile, `people/{uid}`: both riders read it (firebase/firestore.rules).
abstract interface class ProfileRepository {
  /// Writes the profile. Completes once the server has it; the write waits in
  /// Firestore's queue while offline, so callers don't wait on it.
  Future<void> save(Account account, {required String language});
}

class FirestoreProfiles implements ProfileRepository {
  FirestoreProfiles([FirebaseFirestore? db])
    : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  @override
  Future<void> save(Account account, {required String language}) {
    final name = account.name.trim();
    return _db.doc('people/${account.uid}').set({
      // The rules want 1 to 80 characters.
      'name': name.isEmpty
          ? 'Rider'
          : name.substring(0, name.length.clamp(1, 80)),
      'photoUrl': account.photoUrl,
      'language': language,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
