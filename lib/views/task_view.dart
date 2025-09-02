import 'package:flutter/material.dart';
import 'package:tasks_flutter/repository/in_memory_task_repository.dart';
import 'package:tasks_flutter/view_models/task_view_model.dart';

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
    _taskViewModel = TaskViewModel(InMemoryTaskRepository());
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Add a new task',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(width: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _add(),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _add,
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _add() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    if (title.isNotEmpty) {
      _taskViewModel.add(title, description: description);
      _titleController.clear();
    }
  }
}
