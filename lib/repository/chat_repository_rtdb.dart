import 'package:firebase_database/firebase_database.dart';
import 'package:tasks_flutter/model/chat_model.dart';
import 'package:tasks_flutter/repository/chat_repository.dart';

class ChatRepositoryRtdb implements ChatRepository {
  final FirebaseDatabase _database;
  ChatRepositoryRtdb({FirebaseDatabase? database})
    : _database = database ?? FirebaseDatabase.instance;

  DatabaseReference _roomMessages(String roomId) =>
      _database.ref('rooms/$roomId/messages');

  @override
  Stream<List<ChatModel>> streamMessages(String roomId, {int limit = 100}) {
    return _roomMessages(
      roomId,
    ).orderByChild('ts').limitToLast(limit).onValue.map((event) {
      final value = event.snapshot.value;
      final items = <ChatModel>[];
      if (value is Map) {
        value.forEach((k, v) {
          if (v is Map) {
            items.add(ChatModel.fromMap(v, id: k));
          }
        });
      } else if (value is List) {
        for (var i = 0; i < value.length; i++) {
          final v = value[i];
          if (v is Map) {
            items.add(ChatModel.fromMap(v, id: '$i'));
          }
        }
      }
      items.sort((a, b) => a.ts.compareTo(b.ts));
      return items;
    });
  }

  @override
  Future<void> sendMessage({
    required String roomId,
    required String uid,
    required String text,
    String? name,
  }) async {
    final ref = _roomMessages(roomId).push();
    await ref.set({
      'uid': uid,
      'name': name ?? 'User',
      'text': text,
      'ts': ServerValue.timestamp,
    });
  }
}
