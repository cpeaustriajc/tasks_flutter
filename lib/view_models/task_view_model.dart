import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository.dart';

class TaskViewModel extends ChangeNotifier {
  final TaskRepository _taskRepository;

  TaskViewModel(this._taskRepository);

  final List<TaskModel> _tasks = [];

  bool _isLoading = false;

  List<TaskModel> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;

  Future<void> getTasks() async {
    _isLoading = true;
    notifyListeners();
    final fetched = await _taskRepository.getTasks();
    _tasks
      ..clear()
      ..addAll(fetched);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> add(String title, {String description = ''}) async {
    final task = TaskModel(title: title, description: description);

    await _taskRepository.addTask(task);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> toggle(int id) async {
    final task = _tasks.firstWhere((task) => task.id == id);
    final updatedTask = task.copyWith(isCompleted: !task.isCompleted);

    await _taskRepository.updateTask(updatedTask);
    final taskIndex = _tasks.indexWhere((task) => task.id == id);

    if (taskIndex != -1) {
      _tasks[taskIndex] = updatedTask;
      notifyListeners();
    }
  }

  Future<void> remove(int id) async {
    await _taskRepository.deleteTask(id);
  }
}
