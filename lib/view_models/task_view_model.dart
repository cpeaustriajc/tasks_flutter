import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskViewModel(this._taskRepository);

  final List<TaskModel> _tasks = [];

  bool _isLoading = false;

  bool _disposed = false;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> getTasks() async {
    if (_disposed) return;
    _isLoading = true;
    _notify();

    try {
      final fetched = await _taskRepository.getTasks();
      _tasks
        ..clear()
        ..addAll(fetched);
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> add(
    String title, {
    String description = '',
    String? imagePath,
    String? videoUrl,
  }) async {
    final task = TaskModel(
      title: title,
      description: description,
      imagePath: imagePath,
      videoUrl: videoUrl,
    );

    await _taskRepository.addTask(task);
    _tasks.add(task);
    _notify();
  }

  Future<void> toggle(int id) async {
    final task = _tasks.firstWhere((task) => task.id == id);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    await _taskRepository.updateTask(updatedTask);
    final taskIndex = _tasks.indexWhere((task) => task.id == id);

    if (taskIndex != -1) {
      _tasks[taskIndex] = updatedTask;
      _notify();
    }
  }

  Future<void> remove(int id) async {
    await _taskRepository.deleteTask(id);
    _tasks.removeWhere((task) => task.id == id);
    _notify();
  }
}
