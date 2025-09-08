import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository.dart';

class InMemoryTaskRepository implements TaskRepository {
  final List<TaskModel> _tasks = [];

  @override
  Future<List<TaskModel>> getTasks({required String userId}) async {
    return List.unmodifiable(
      _tasks.where((t) => t.userId == userId),
    );
  }

  @override
  Future<void> addTask(TaskModel task) async {
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(int id, {String? userId}) async {
    _tasks.removeWhere((t) => t.id == id);
  }
}
