import 'package:flutter/material.dart';

class AppNavigationSingleton {
  AppNavigationSingleton._();

  static final AppNavigationSingleton instance = AppNavigationSingleton._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<T?> pushNamed<T extends Object?> (String routeName, {Object? arguments}) {
    return navigatorKey.currentState!.pushNamed<T>(routeName, arguments: arguments);
  }

  void pop<T extends Object?>([T? result]) {
    navigatorKey.currentState!.pop<T>(result);
  }
}
