import 'package:sqflite/sqflite.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository.dart';
import 'package:tasks_flutter/singleton/app_database_singleton.dart';

class SqliteTaskRepository implements TaskRepository {
  static const _table = 'tasks';

  Future<Database> get _database async =>
      AppDatabaseSingleton.instance.database;

  @override
  Future<List<TaskModel>> getTasks() async {
    final database = await _database;
    final rows = await database.query(_table, orderBy: 'id DESC');

    return rows.map(_fromRow).toList();
  }

  @override
  Future<void> addTask(TaskModel task) async {
    final database = await _database;
    await database.insert(
      _table,
      _toInsertRow(task),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final database = await _database;
    await database.update(
      _table,
      _toUpdateRow(task),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  @override
  Future<void> deleteTask(int id) async {
    final database = await _database;
    await database.delete(_table, where: 'id =  ?', whereArgs: [id]);
  }

  Map<String, Object?> _toInsertRow(TaskModel task) => {
    'id': task.id,
    'title': task.title,
    'description': task.description,
    'isCompleted': task.isCompleted ? 1 : 0,
    'imagePath': task.imagePath,
  };

  Map<String, Object?> _toUpdateRow(TaskModel task) => {
    'title': task.title,
    'description': task.description,
    'isCompleted': task.isCompleted ? 1 : 0,
    'imagePath': task.imagePath,
  };

  TaskModel _fromRow(Map<String, Object?> row) {
    return TaskModel.fromMap(row);
  }
}
