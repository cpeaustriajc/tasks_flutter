class PresenceUserModel {
  final String uid;
  final String? name;
  final String status;
  final int lastChanged;

  PresenceUserModel({
    required this.uid,
    required this.status,
    required this.lastChanged,
    this.name,
  });

  factory PresenceUserModel.fromMap(String uid, Map<dynamic, dynamic> data) {
    return PresenceUserModel(
      uid: uid,
      status: data['status']?.toString() ?? 'offline',
      name: data['name'] as String?,
      lastChanged: _asInt(data['last_changed']),
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;

    return 0;
  }
}
