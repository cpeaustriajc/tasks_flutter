import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final int createdAt;
  final int updatedAt;

  const UserModel({
    required this.uid,
    required this.createdAt,
    required this.updatedAt,
    this.email,
    this.displayName,
  });

  factory UserModel.fromMap(String uid, Map<dynamic, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email']?.toString(),
      displayName: data['display_name']?.toString(),
      createdAt: _asInt(data['created_at']),
      updatedAt: _asInt(data['updated_at']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
