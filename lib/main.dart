import 'package:flutter/material.dart';
import 'package:tasks_flutter/service/app_navigation_service.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(TaskApp());
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigationService.instance.navigatorKey,
      onGenerateRoute: AppRouteFactory.onGenerateRoute,
      initialRoute: AppRoutes.home,
    );
  }
}
