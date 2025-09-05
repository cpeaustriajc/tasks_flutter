import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/model/chat_model.dart';
import 'package:tasks_flutter/model/presence_user_model.dart';
import 'package:tasks_flutter/repository/chat_repository.dart';
import 'package:tasks_flutter/service/presence_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatRepository _chatRepository;
  final PresenceService _presenceService;

  ChatViewModel(this._chatRepository, this._presenceService);

  final String roomId = 'global';

  List<ChatModel> _messages = [];
  List<PresenceUserModel> _presenceList = [];
  bool _isLoading = true;

  List<ChatModel> get messages => _messages;
  List<PresenceUserModel> get onlineList =>
      _presenceList.where((p) => p.status == 'online').toList(growable: false);
  bool get isLoading => _isLoading;

  StreamSubscription<List<ChatModel>>? _messagesSubscription;
  StreamSubscription<List<PresenceUserModel>>? _presenceSubscription;

  Future<void> init({required String uid, String? name}) async {
    _isLoading = true;
    notifyListeners();

    _messagesSubscription = _chatRepository.streamMessages(roomId).listen((
      data,
    ) {
      _messages = data;
      _isLoading = false; // stop spinner on first batch (even if empty)
      notifyListeners();
    });

    await _presenceService.goOnline(uid: uid, name: name);
    _presenceSubscription = _presenceService.streamOnlineUsers().listen((data) {
      _presenceList = data;
      notifyListeners();
    });
  }

  Future<void> send(String uid, String text, {String? name}) async {
    final t = text.trim();
    if (t.isEmpty) return;
    await _chatRepository.sendMessage(
      roomId: roomId,
      uid: uid,
      text: t,
      name: name,
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _presenceSubscription?.cancel();
    super.dispose();
  }
}
