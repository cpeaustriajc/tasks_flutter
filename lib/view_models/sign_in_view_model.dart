import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasks_flutter/repository/user_repository_firestore.dart';

class SignInViewModel extends ChangeNotifier {
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
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        final repo = UserRepositoryFirestore();
        await repo.ensureUserProfileExists(
          uid: credential.user!.uid,
          email: credential.user!.email,
          displayName: credential.user!.displayName,
        );
        await repo.saveUserProfile(
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
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    try {
      final GoogleSignInAccount googleUser = await googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final result = await FirebaseAuth.instance.signInWithCredential(credential);
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
