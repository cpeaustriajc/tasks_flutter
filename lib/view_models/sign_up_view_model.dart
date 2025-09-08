import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/repository/user_repository_firestore.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';

class SignUpViewModel extends ChangeNotifier {
  String? _errorMessage;
  bool _isLoading = false;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (result.user != null) {
        final repo = UserRepositoryFirestore();
        await repo.ensureUserProfileExists(
          uid: result.user!.uid,
          email: result.user!.email,
          displayName: result.user!.displayName,
        );
        await repo.saveUserProfile(
          uid: result.user!.uid,
          email: result.user!.email,
          displayName: result.user!.displayName,
        );
      }

      if (result.user != null) {
        _errorMessage = null;
        AppNavigationSingleton.instance.pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          _errorMessage = 'The password provided is too weak.';
          break;
        case 'invalid-email':
          _errorMessage = 'The email address is not valid.';
          break;
        case 'email-already-in-use':
          _errorMessage = 'The account already exists for that email.';
          break;
        default:
          _errorMessage = e.message;
      }
    } catch (e) {
      _errorMessage = 'An unknown error occurred.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
