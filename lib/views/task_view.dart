import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository_sqlite.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/view_models/task_view_model.dart';
import 'package:tasks_flutter/views/chat_view.dart';

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    _taskViewModel = TaskViewModel(SqliteTaskRepository());
    _taskViewModel.getTasks();
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
      body: IndexedStack(
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
                    onDismissed: (_) => _taskViewModel.remove(task.id),
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
                                  _isYouTubeUrl(task.videoUrl!)
                                      ? _TaskYouTubePlayer(url: task.videoUrl!)
                                      : _TaskVideoPlayer(
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
                        onPressed: () => _taskViewModel.remove(task.id),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          ChatView(),
        ],
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
      await _taskViewModel.add(
        result.title.trim(),
        description: result.description.trim(),
        imagePath: result.imagePath,
        videoUrl: result.videoUrl,
      );
    }
  }
}

class _TaskVideoPlayer extends StatefulWidget {
  const _TaskVideoPlayer({required this.videoUrl});
  final String videoUrl;

  @override
  State<_TaskVideoPlayer> createState() => _TaskVideoPlayerState();
}

class _TaskVideoPlayerState extends State<_TaskVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(false)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _error = 'Unable to load video');
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }

    if (!_ready) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final aspect = _controller.value.aspectRatio == 0
        ? 16 / 9
        : _controller.value.aspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Container(
                  color: Colors.black26,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }
}

class _TaskYouTubePlayer extends StatefulWidget {
  const _TaskYouTubePlayer({required this.url});
  final String url;

  @override
  State<_TaskYouTubePlayer> createState() => _TaskYouTubePlayerState();
}

class _TaskYouTubePlayerState extends State<_TaskYouTubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = _extractYouTubeId(widget.url);
    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
          enableJavaScript: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return const Text(
        'Invalid YouTube URL',
        style: TextStyle(color: Colors.red),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(controller: c),
    );
  }
}

bool _isYouTubeUrl(String url) {
  final u = Uri.tryParse(url);
  if (u == null || !(u.isScheme('http') || u.isScheme('https'))) return false;
  final host = u.host.toLowerCase();
  if (host.contains('youtube.com') || host.contains('youtu.be')) return true;
  return false;
}

String? _extractYouTubeId(String url) {
  final u = Uri.tryParse(url);
  if (u == null) return null;
  final host = u.host.toLowerCase();
  if (host.contains('youtu.be')) {
    final id = u.pathSegments.isNotEmpty ? u.pathSegments.first : null;
    return (id != null && id.isNotEmpty) ? id : null;
  }
  if (host.contains('youtube.com')) {
    final id = u.queryParameters['v'];
    if (id != null && id.isNotEmpty) return id;
    if (u.pathSegments.length >= 2 &&
        (u.pathSegments.first == 'shorts' || u.pathSegments.first == 'embed')) {
      return u.pathSegments[1];
    }
  }
  return null;
}
