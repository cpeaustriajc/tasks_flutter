import 'package:tasks_flutter/model/user_model.dart';

abstract class UserRepository {
  Stream<List<UserModel>> streamUsers();
  Future<void> saveUserProfile({
    required String uid,
    String? email,
    String? displayName,
  });

  Future<void> ensureUserProfileExists({
    required String uid,
    String? email,
    String? displayName,
  });
}
