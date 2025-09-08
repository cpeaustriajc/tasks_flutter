import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tasks_flutter/model/task_model.dart';
import 'package:tasks_flutter/repository/task_repository.dart';

/// Firestore implementation storing tasks under users/{uid}/tasks/{taskId}.
class FirestoreTaskRepository implements TaskRepository {
  final FirebaseFirestore _firestore;
  FirestoreTaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _userTasksCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('tasks');

  @override
  Future<List<TaskModel>> getTasks({required String userId}) async {
    final snap = await _userTasksCol(userId).orderBy('id', descending: true).get();
    return snap.docs.map((d) => TaskModel.fromMap(d.data())).toList();
  }

  @override
  Future<List<TaskModel>> getTasksPage({
    required String userId,
    int? startAfterId,
    required int limit,
  }) async {
    Query<Map<String, dynamic>> q = _userTasksCol(userId).orderBy('id', descending: true).limit(limit);
    if (startAfterId != null) {
      q = q.startAfter([startAfterId]);
    }
    final snap = await q.get();
    return snap.docs.map((d) => TaskModel.fromMap(d.data())).toList();
  }

  @override
  Future<void> addTask(TaskModel task) async {
    final doc = _userTasksCol(task.userId).doc(task.id.toString());
    await doc.set(task.toMap());
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    final doc = _userTasksCol(task.userId).doc(task.id.toString());
    await doc.update(task.toMap());
  }

  @override
  Future<void> deleteTask(int id, {String? userId}) async {
    if (userId == null) return; // cannot delete without owner
    await _userTasksCol(userId).doc(id.toString()).delete();
  }
}
