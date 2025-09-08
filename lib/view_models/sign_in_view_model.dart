import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasks_flutter/repository/user_repository.dart';
import 'package:tasks_flutter/repository/user_repository_firestore.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
    UserRepository? userRepository,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
        _userRepository = userRepository ?? UserRepositoryFirestore();

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  final UserRepository _userRepository;

  String? _errorMessage;
  bool _isLoading = false;

  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        await _userRepository.ensureUserProfileExists(
          uid: credential.user!.uid,
          email: credential.user!.email,
          displayName: credential.user!.displayName,
        );
        await _userRepository.saveUserProfile(
          uid: credential.user!.uid,
          email: credential.user!.email,
          displayName: credential.user!.displayName,
        );
      }
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found for that email.';
          break;
        case 'invalid-email':
          _errorMessage = 'The email address is not valid.';
          break;
        case 'user-disabled':
          _errorMessage = 'This user has been disabled.';
          break;
        case 'wrong-password':
          _errorMessage = 'Wrong password provided for that user.';
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

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    await _googleSignIn.initialize();

    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
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
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-disabled':
          _errorMessage = 'This user has been disabled.';
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
