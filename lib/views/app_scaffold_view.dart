import 'package:flutter/material.dart';

class AppScaffoldView extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final FloatingActionButton? floatingActionButton;
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;
  final List<BottomNavigationBarItem>? tabs;

  const AppScaffoldView({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentIndex,
    this.onTabSelected,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: (tabs != null && currentIndex != null)
          ? BottomNavigationBar(
              items: tabs!,
              currentIndex: currentIndex!,
              onTap: onTabSelected,
            )
          : null,
    );
  }
}
