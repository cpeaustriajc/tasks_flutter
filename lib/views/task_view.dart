import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/repository/sqlite_task_repository.dart';
import 'package:tasks_flutter/service/app_navigation_service.dart';
import 'package:tasks_flutter/view_models/task_view_model.dart';
import 'package:tasks_flutter/views/task_create_view.dart';

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
      appBar: AppBar(title: const Text('Task Manager')),
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
                  subtitle: task.description.isNotEmpty
                      ? Text(task.description)
                      : null,
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
    final result = await AppNavigationService.instance
        .pushNamed<TaskCreateResult>(AppRoutes.create);

    if (result != null && result.title.trim().isNotEmpty) {
      await _taskViewModel.add(
        result.title.trim(),
        description: result.description.trim(),
      );
    }
  }
}
