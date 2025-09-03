import 'package:flutter/material.dart';
import 'package:tasks_flutter/views/task_create_view.dart';
import 'package:tasks_flutter/views/task_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String create = '/create';
}

class AppRouteFactory {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const TaskView());
      case '/create':
        return MaterialPageRoute(builder: (_) => const TaskCreateFormView());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
