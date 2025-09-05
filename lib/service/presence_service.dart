import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:tasks_flutter/model/presence_user_model.dart';

class PresenceService {
  final FirebaseDatabase _database;
  PresenceService({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference _statusRef(String uid) => _database.ref('status/$uid');
  DatabaseReference get _statusRoot => _database.ref('status');
  DatabaseReference get _infoConnected => _database.ref('.info/connected');

  Future<void> goOnline({required String uid, String? name}) async {
    final meRef = _statusRef(uid);
    await meRef.update({
      'name': name,
      'status': 'online',
      'last_changed': ServerValue.timestamp,
    });

    final onDisconnect = meRef.onDisconnect();
    await onDisconnect.update({
      'status': 'offline',
      'last_changed': ServerValue.timestamp,
    });
    _infoConnected.onValue.listen((_) {});
  }

  Future<void> goOffline({required String uid}) async {
    await _statusRef(
      uid,
    ).update({'status': 'offline', 'last_changed': ServerValue.timestamp});
  }

  Stream<List<PresenceUserModel>> streamOnlineUsers() {
    return _statusRoot.onValue.map((event) {
      final value = event.snapshot.value;
      final list = <PresenceUserModel>[];

      if (value is Map) {
        value.forEach((uid, v) {
          if (v is Map) {
            list.add(PresenceUserModel.fromMap(uid as String, v));
          }
        });
      }
      list.sort((a, b) => a.uid.compareTo(b.uid));
      return list;
    });
  }
}
