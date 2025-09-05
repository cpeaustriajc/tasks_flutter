import 'package:tasks_flutter/model/chat_model.dart';

abstract class ChatRepository {
  Stream<List<ChatModel>> streamMessages(String roomId, {int limit});

  Future<void> sendMessage({
    required String roomId,
    required String uid,
    required String text,
    String? name,
  });
}
