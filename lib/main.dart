import 'package:flutter/material.dart';
import 'package:tasks_flutter/views/task_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: TaskView());
  }
}
