import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/views/people_list_view.dart';
import 'package:tasks_flutter/views/chat_conversation_view.dart';
import 'package:tasks_flutter/model/user_model.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository_sqlite.dart';
import 'package:tasks_flutter/repository/task_repository_firestore.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/strategy/video_url_strategy.dart';
import 'package:tasks_flutter/view_models/task_view_model.dart';
import 'package:tasks_flutter/views/widgets/task_video_player.dart';
import 'package:tasks_flutter/views/widgets/task_youtube_player.dart';

enum _AccountMenuAction { signOut }

class TaskView extends StatefulWidget {
  const TaskView({super.key});

  @override
  State<TaskView> createState() => _TaskViewState();
}

class _TaskViewState extends State<TaskView> {
  late final TaskViewModel _taskViewModel;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int _selectedIndex = 0;
  UserModel? _selectedChatUser;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool _migrated = false;

  @override
  void initState() {
    super.initState();
    _taskViewModel = TaskViewModel(SqliteTaskRepository());
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _taskViewModel.getTasks(userId: currentUser.uid);
    } else {
      FirebaseAuth.instance.authStateChanges().first.then((u) {
        if (u != null) _taskViewModel.getTasks(userId: u.uid);
      });
    }
  }

  @override
  void dispose() {
    _taskViewModel.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Manager'),
        actions: [
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return IconButton(
                  tooltip: 'Sign In',
                  icon: const Icon(Icons.login),
                  onPressed: () => AppNavigationSingleton.instance.pushNamed(
                    AppRoutes.signIn,
                  ),
                );
              }

              return PopupMenuButton(
                tooltip: 'Account',
                icon: const Icon(Icons.person),
                onSelected: (action) async {
                  switch (action) {
                    case _AccountMenuAction.signOut:
                      try {
                        await FirebaseAuth.instance.signOut();
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error signing out.')),
                          );
                        }
                      }
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: _AccountMenuAction.signOut,
                    child: Text('Sign Out (${user.email})'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          final authUser = authSnap.data;
          if (authUser != null && !_migrated) {
            if (!_taskViewModel.isLoading) {
              final sqliteTasks = _taskViewModel.tasks
                  .where((t) => t.userId == authUser.uid || t.userId == 'unknown')
                  .toList();
              final firestoreRepo = FirestoreTaskRepository();
              Future(() async {
                for (final task in sqliteTasks) {
                  final taskWithOwner = (task.userId == authUser.uid)
                      ? task
                      : task.copyWith(userId: authUser.uid);
                  await firestoreRepo.addTask(taskWithOwner);
                }
                if (mounted) {
                  await _taskViewModel.switchRepository(
                    firestoreRepo,
                    userId: authUser.uid,
                  );
                  setState(() {
                    _migrated = true;
                  });
                }
              });
            }
          }
          return IndexedStack(
        index: _selectedIndex,
        children: [
          ListenableBuilder(
            listenable: _taskViewModel,
            builder: (context, _) {
              if (_taskViewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_taskViewModel.tasks.isEmpty) {
                return const Center(child: Text('No tasks available.'));
              }
              return ListView.builder(
                itemCount: _taskViewModel.tasks.length,
                itemBuilder: (context, index) {
                  final task = _taskViewModel.tasks[index];
                  final hasImage = (task.imagePath ?? '').isNotEmpty;
                  final hasVideo = (task.videoUrl ?? '').isNotEmpty;
                  return Dismissible(
                    key: ValueKey(task.id),
                    background: Container(color: Colors.redAccent),
                    onDismissed: (_) {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        _taskViewModel.remove(task.id, userId: user.uid);
                      }
                    },
                    child: CheckboxListTile(
                      value: task.isCompleted,
                      onChanged: (_) => _taskViewModel.toggle(task.id),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      subtitle:
                          (task.description.isNotEmpty || hasImage || hasVideo)
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (task.description.isNotEmpty)
                                  Text(task.description),
                                if (hasImage) ...[
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(task.imagePath!),
                                      height: 120,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ],
                                if (hasVideo) ...[
                                  const SizedBox(height: 8),
                                  VideoUrlStrategy.instance.isYouTube(
                                        task.videoUrl!,
                                      )
                                      ? TaskYoutubePlayer(url: task.videoUrl!)
                                      : TaskVideoPlayer(
                                          videoUrl: task.videoUrl!,
                                        ),
                                ],
                              ],
                            )
                          : null,
                      isThreeLine: hasImage || task.description.isNotEmpty,
                      secondary: IconButton(
                        tooltip: 'Delete Task',
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            _taskViewModel.remove(task.id, userId: user.uid);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // Chat tab (people list or conversation)
          _ChatTab(
            selectedUser: _selectedChatUser,
            onUserSelected: (u) => setState(() => _selectedChatUser = u),
            onBackFromConversation: () =>
                setState(() => _selectedChatUser = null),
          ),
        ],
          );
        },
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: _goToCreate,
              tooltip: 'Add Task',
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Tasks'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Future<void> _goToCreate() async {
    final result =
        await AppNavigationSingleton.instance.pushNamed(AppRoutes.create)
            as TaskModel?;

    if (result != null && result.title.trim().isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'unknown';
      await _taskViewModel.add(
        result.title.trim(),
        description: result.description.trim(),
        imagePath: result.imagePath,
        videoUrl: result.videoUrl,
        userId: userId,
      );
    }
  }
}

class _ChatTab extends StatelessWidget {
  final UserModel? selectedUser;
  final ValueChanged<UserModel> onUserSelected;
  final VoidCallback onBackFromConversation;
  const _ChatTab({
    required this.selectedUser,
    required this.onUserSelected,
    required this.onBackFromConversation,
  });

  @override
  Widget build(BuildContext context) {
    if (selectedUser != null) {
      return ChatConversationView(
        initialUser: selectedUser,
        onBack: onBackFromConversation,
      );
    }
    // Reuse full-screen people list inside tab (without extra route push)
    return PeopleListView();
  }
}
