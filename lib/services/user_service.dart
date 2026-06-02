import 'package:cloud_firestore/cloud_firestore.dart';

import '../constants/constants.dart';
import '../models/user_model.dart';

/// Firestore CRUD for the `users` collection, keyed by the Firebase Auth uid.
class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection(FirestoreCollections.users);

  /// Returns the profile document, or null if onboarding hasn't completed.
  Future<UserModel?> getUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Creates the profile document at the end of onboarding.
  Future<UserModel> createUser({
    required String uid,
    required String phone,
    required UserRole role,
    String? name,
  }) async {
    final now = DateTime.now();
    final user = UserModel(
      id: uid,
      name: name,
      phone: phone,
      role: role,
      createdAt: now,
      updatedAt: now,
    );
    await _users.doc(uid).set(user.toFirestore());
    return user;
  }

  /// Persists a profile change (e.g. the role toggle on the feed).
  Future<UserModel> updateUser(UserModel user) async {
    final updated = user.copyWith(updatedAt: DateTime.now());
    await _users.doc(user.id).update(updated.toFirestore());
    return updated;
  }
}