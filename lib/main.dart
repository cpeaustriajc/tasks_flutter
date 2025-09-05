import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/firebase_options.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/views/gates/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final user = FirebaseAuth.instance.currentUser;
  runApp(
    TaskApp(initialRoute: user == null ? AppRoutes.signIn : AppRoutes.home),
  );
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key, required this.initialRoute});
  final String initialRoute;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: AppNavigationSingleton.instance.navigatorKey,
      onGenerateRoute: AppRouteFactory.onGenerateRoute,
      home: const AuthGate(),
    );
  }
}
