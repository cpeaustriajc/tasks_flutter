import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasks_flutter/model/user_model.dart';
import 'package:tasks_flutter/repository/user_repository.dart';

class UserRepositoryFirestore implements UserRepository {
  final FirebaseFirestore _firestore;
  UserRepositoryFirestore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  @override
  Stream<List<UserModel>> streamUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromMap(doc.id, data);
      }).toList();
      users.sort((a, b) => (a.displayName ?? a.uid)
          .toLowerCase()
          .compareTo((b.displayName ?? b.uid).toLowerCase()));
      return users;
    });
  }

  @override
  Future<void> saveUserProfile({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    final docRef = _usersCollection.doc(uid);
    await _firestore.runTransaction((txn) async {
      final snap = await txn.get(docRef);
      final serverTime = FieldValue.serverTimestamp();
      if (snap.exists) {
        txn.update(docRef, {
          'email': email,
          'display_name': displayName ?? email?.split('@').first,
          'updated_at': serverTime,
        });
      } else {
        txn.set(docRef, {
          'email': email,
          'display_name': displayName ?? email?.split('@').first,
          'created_at': serverTime,
          'updated_at': serverTime,
        });
      }
    });
  }

  @override
  Future<void> ensureUserProfileExists({
    required String uid,
    String? email,
    String? displayName,
  }) async {
    final docRef = _usersCollection.doc(uid);
    final snap = await docRef.get();
    if (snap.exists) return; // Already present.
    await docRef.set({
      'email': email,
      'display_name': displayName ?? email?.split('@').first,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

}
