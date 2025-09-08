import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:tasks_flutter/repository/user_repository.dart';
import 'package:tasks_flutter/repository/user_repository_firestore.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({
    FirebaseAuth? auth,
    UserRepository? userRepository,
    this.navigateOnSuccess = true,
    void Function()? onSuccessNavigate,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _userRepository = userRepository ?? UserRepositoryFirestore(),
        _onSuccessNavigate = onSuccessNavigate;

  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  final bool navigateOnSuccess;
  final void Function()? _onSuccessNavigate; // for UI layer injection

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
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.user != null) {
        await _userRepository.ensureUserProfileExists(
          uid: result.user!.uid,
          email: result.user!.email,
          displayName: result.user!.displayName,
        );
        await _userRepository.saveUserProfile(
          uid: result.user!.uid,
          email: result.user!.email,
          displayName: result.user!.displayName,
        );
      }

      if (result.user != null) {
        _errorMessage = null;
        // Actual navigation is delegated to UI via callback for testability.
        if (navigateOnSuccess) {
          _onSuccessNavigate?.call();
        }
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
