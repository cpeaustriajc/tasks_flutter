import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/model/user_model.dart';
import 'package:tasks_flutter/repository/user_repository_firestore.dart';
import 'package:tasks_flutter/service/presence_service.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/view_models/people_view_model.dart';

class PeopleListView extends StatefulWidget {
  const PeopleListView({super.key});

  @override
  State<PeopleListView> createState() => _PeopleListViewState();
}

class _PeopleListViewState extends State<PeopleListView> {
  late final PeopleViewModel _peopleViewModel;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _peopleViewModel = PeopleViewModel(
      UserRepositoryFirestore(),
      PresenceService(),
    );
  }

  @override
  void dispose() {
    _peopleViewModel.dispose();
    super.dispose();
  }

  void _openConversation(UserModel other) {
    AppNavigationSingleton.instance.pushNamed(
      AppRoutes.chatConversation,
      arguments: {
        'user': other,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final currentUser = snapshot.data;
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('People')),
            body: Center(
              child: ElevatedButton(
                onPressed: () => AppNavigationSingleton.instance.pushNamed(AppRoutes.signIn),
                child: const Text('Sign In'),
              ),
            ),
          );
        }

        if (!_initialized) {
          _initialized = true;
          _peopleViewModel.init(
            uid: currentUser.uid,
            name: currentUser.displayName ?? currentUser.email,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('People'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: ListenableBuilder(
            listenable: _peopleViewModel,
            builder: (context, _) {
              if (_peopleViewModel.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              final people = _peopleViewModel.users
                  .where((u) => u.uid != currentUser.uid)
                  .toList();
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search people',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: _peopleViewModel.setFilter,
                    ),
                  ),
                  if (people.isEmpty)
                    const Expanded(
                      child: Center(child: Text('No other users found.')),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: people.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final person = people[index];
                          final name = person.displayName ?? person.email ?? person.uid;
                          final isOnline = _peopleViewModel.isOnline(person.uid);
                          return ListTile(
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  child: Text(
                                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                  ),
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.surface,
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.green,
                                        radius: 5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(name),
                            subtitle: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: TextStyle(color: isOnline ? Colors.green : null),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _openConversation(person),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
