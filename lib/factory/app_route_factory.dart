import 'package:flutter/material.dart';
import 'package:tasks_flutter/views/sign_in_view.dart';
import 'package:tasks_flutter/views/sign_up_view.dart';
import 'package:tasks_flutter/views/task_create_view.dart';
import 'package:tasks_flutter/views/task_view.dart';
import 'package:tasks_flutter/views/people_list_view.dart';
import 'package:tasks_flutter/views/chat_conversation_view.dart';

class AppRoutes {
  static const String home = '/';
  static const String create = '/create';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String people = '/people';
  static const String chatConversation = '/chat'; // expects arguments: { user: UserModel }
}

class AppRouteFactory {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const TaskView());
      case '/create':
        return MaterialPageRoute(builder: (_) => const TaskCreateFormView());
      case '/sign-in':
        return MaterialPageRoute(builder: (_) => SignInView());
      case '/sign-up':
        return MaterialPageRoute(builder: (_) => SignUpView());
      case AppRoutes.people:
        return MaterialPageRoute(builder: (_) => const PeopleListView());
      case AppRoutes.chatConversation:
        return MaterialPageRoute(
          builder: (ctx) {
            final args = settings.arguments;
            return ChatConversationView(arguments: args);
          },
        );
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
