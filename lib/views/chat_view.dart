import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/repository/chat_repository_rtdb.dart';
import 'package:tasks_flutter/service/presence_service.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/view_models/chat_view_model.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final ChatViewModel _vm;
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _initialized = false;
  int _lastCount = 0;

  @override
  void initState() {
    super.initState();
    _vm = ChatViewModel(ChatRepositoryRtdb(), PresenceService());
  }

  @override
  void dispose() {
    _vm.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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
    final text = _textController.text;
    _textController.clear();
    await _vm.send(
      user.uid,
      text,
      name: user.displayName ?? user.email ?? 'User',
    );
    _scrollAfterFrame();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;

        if (user == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Sign in to access the chat'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => AppNavigationSingleton.instance.pushNamed(
                    AppRoutes.signIn,
                  ),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign In'),
                ),
              ],
            ),
          );
        }

        if (!_initialized) {
          _initialized = true;
          _vm.init(uid: user.uid, name: user.displayName ?? user.email);
        }

        return ListenableBuilder(
          listenable: _vm,
          builder: (context, _) {
            if (_vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final messages = _vm.messages;
            if (messages.length != _lastCount) {
              _lastCount = messages.length;
              _scrollAfterFrame();
            }

            return Column(
              children: [
                if (_vm.onlineList.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          const Text('Online:'),
                          ..._vm.onlineList.map(
                            (p) => _OnlineChip(name: p.name ?? p.uid),
                          ),
                        ],
                      ),
                    ),
                  ),

                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final m = messages[index];
                      final isMe = m.uid == user.uid;
                      final bubbleColor = isMe
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest;

                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: bubbleColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!isMe)
                                    Text(
                                      m.name ??
                                          (m.uid == 'echo' ? 'Echo' : 'User'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  Text(m.text),
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
                            onSubmitted: (_) => _send(user),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Send',
                          icon: const Icon(Icons.send),
                          onPressed: () => _send(user),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _OnlineChip extends StatelessWidget {
  const _OnlineChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = cs.secondaryContainer;
    final fg = cs.onSecondaryContainer;

    return Tooltip(
      message: name,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Chip(
          avatar: const _PresenceDot(color: Colors.green),
          label: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: fg),
          ),
          backgroundColor: bg,
          side: BorderSide(color: cs.outlineVariant),
          shape: const StadiumBorder(),
          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
        ),
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
