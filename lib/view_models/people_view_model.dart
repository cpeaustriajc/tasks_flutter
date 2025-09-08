import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/model/user_model.dart';
import 'package:tasks_flutter/model/presence_user_model.dart';
import 'package:tasks_flutter/repository/user_repository.dart';
import 'package:tasks_flutter/service/presence_service.dart';

class PeopleViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final PresenceService _presenceService;
  PeopleViewModel(this._userRepository, this._presenceService);

  List<UserModel> _allUsers = [];
  List<PresenceUserModel> _presenceUsers = [];
  bool _isLoading = true;
  String _filterQuery = '';

  bool get isLoading => _isLoading;
  String get filterQuery => _filterQuery;

  List<UserModel> get users {
    final lower = _filterQuery.trim().toLowerCase();
    final filtered = lower.isEmpty
        ? _allUsers
        : _allUsers.where((u) {
            final name = u.displayName ?? '';
            final email = u.email ?? '';
            return name.toLowerCase().contains(lower) ||
                email.toLowerCase().contains(lower);
          }).toList();
    return filtered;
  }

  bool isOnline(String uid) => _presenceUsers.any(
        (p) => p.uid == uid && p.status == 'online',
      );

  StreamSubscription<List<UserModel>>? _usersSub;
  StreamSubscription<List<PresenceUserModel>>? _presenceSub;

  Future<void> init({required String uid, String? name}) async {
    _isLoading = true;
    notifyListeners();

    await _presenceService.goOnline(uid: uid, name: name);

    _usersSub = _userRepository.streamUsers().listen((data) {
      _allUsers = data;
      _isLoading = false;
      notifyListeners();
    });

    _presenceSub = _presenceService.streamOnlineUsers().listen((data) {
      _presenceUsers = data;
      notifyListeners();
    });
  }

  void setFilter(String query) {
    _filterQuery = query;
    notifyListeners();
  }

  @override
  void dispose() {
    _usersSub?.cancel();
    _presenceSub?.cancel();
    super.dispose();
  }
}
