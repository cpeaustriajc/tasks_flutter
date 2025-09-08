import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/model/user_model.dart';
import 'package:tasks_flutter/repository/chat_repository_rtdb.dart';
import 'package:tasks_flutter/service/presence_service.dart';
import 'package:tasks_flutter/view_models/chat_view_model.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';

class ChatConversationView extends StatefulWidget {
  final Object? arguments; // legacy route argument map { user: UserModel }
  final UserModel? initialUser; // direct embedding without route args
  final VoidCallback? onBack; // show back button if provided
  const ChatConversationView({super.key, this.arguments, this.initialUser, this.onBack});

  @override
  State<ChatConversationView> createState() => _ChatConversationViewState();
}

class _ChatConversationViewState extends State<ChatConversationView> {
  ChatViewModel? _conversationViewModel;
  bool _conversationInitialized = false;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastCount = 0;
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    if (widget.initialUser != null) {
      _otherUser = widget.initialUser;
    } else if (widget.arguments is Map) {
      final map = widget.arguments as Map;
      final user = map['user'];
      if (user is UserModel) _otherUser = user;
    }
  }

  @override
  void dispose() {
    _conversationViewModel?.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _roomIdFor(String a, String b) {
    final sorted = [a, b]..sort();
    return 'room_${sorted[0]}_${sorted[1]}';
  }

  void _scrollAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 60,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(User user) async {
    final messageText = _textController.text.trim();
    if (messageText.isEmpty) return;
    _textController.clear();
    final conversationViewModel = _conversationViewModel;
    if (conversationViewModel == null) return;
    await conversationViewModel.send(
      user.uid,
      messageText,
      name: user.displayName ?? user.email ?? 'User',
    );
    _scrollAfterFrame();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Chat')),
            body: Center(
              child: ElevatedButton(
                onPressed: () => AppNavigationSingleton.instance.pushNamed(AppRoutes.signIn),
                child: const Text('Sign In'),
              ),
            ),
          );
        }

        if (_otherUser == null) {
          return const Scaffold(
            body: Center(child: Text('No user selected.')),
          );
        }

        final conversationViewModel = _conversationViewModel ??= ChatViewModel(
          ChatRepositoryRtdb(),
          PresenceService(),
          roomId: _roomIdFor(currentUser.uid, _otherUser!.uid),
        );
        if (!_conversationInitialized) {
          _conversationInitialized = true;
          conversationViewModel.init(
            uid: currentUser.uid,
            name: currentUser.displayName ?? currentUser.email,
          );
        }

        return ListenableBuilder(
          listenable: conversationViewModel,
          builder: (context, _) {
            final messages = conversationViewModel.messages;
            if (conversationViewModel.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (messages.length != _lastCount) {
              _lastCount = messages.length;
              _scrollAfterFrame();
            }
            final name = _otherUser!.displayName ?? _otherUser!.email ?? 'User';
            return Scaffold(
              appBar: AppBar(
                leading: widget.onBack != null
                    ? IconButton(
                        tooltip: 'Back',
                        icon: const Icon(Icons.arrow_back),
                        onPressed: widget.onBack,
                      )
                    : null,
                title: Row(children: [
                  CircleAvatar(
                    child: Text(name.substring(0, 1).toUpperCase()),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name)),
                ]),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final m = messages[index];
                        final isMe = m.uid == currentUser.uid;
                        final bubbleColor = isMe
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.surfaceContainerHighest;
                        final textColor = isMe
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: bubbleColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (!isMe)
                                      Text(
                                        m.name ?? 'User',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    Text(
                                      m.text,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Message',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              textInputAction: TextInputAction.send,
                              onSubmitted: (_) => _send(currentUser),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Send',
                            icon: const Icon(Icons.send),
                            onPressed: () => _send(currentUser),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
