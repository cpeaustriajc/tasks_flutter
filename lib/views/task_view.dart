import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository_sqlite.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/view_models/task_view_model.dart';

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
            builder: (context, snapshop) {
              final user = snapshop.data;
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
      body: ListenableBuilder(
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
                  subtitle: (task.description.isNotEmpty || hasImage)
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
      floatingActionButton: FloatingActionButton(
        onPressed: _goToCreate,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
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
      );
    }
  }
}
