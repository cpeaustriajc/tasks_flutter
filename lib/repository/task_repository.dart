import 'package:tasks_flutter/model/task_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getTasks();
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(int id);
}
