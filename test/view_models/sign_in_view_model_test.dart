import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tasks_flutter/repository/user_repository.dart';
import 'package:tasks_flutter/view_models/sign_in_view_model.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}
class _MockUserCredential extends Mock implements UserCredential {}
class _MockUser extends Mock implements User {}
class _MockGoogleSignIn extends Mock implements GoogleSignIn {}
class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const AuthCredential(providerId: 'password', signInMethod: 'password'));
  });

  group('SignInViewModel.signInWithPassword', () {
    late _MockFirebaseAuth auth;
    late _MockUserRepository userRepo;
    late SignInViewModel vm;

    setUp(() {
      auth = _MockFirebaseAuth();
      userRepo = _MockUserRepository();
      vm = SignInViewModel(auth: auth, userRepository: userRepo, googleSignIn: _MockGoogleSignIn());
    });

    test('success path stores profile via repository and clears error', () async {
      final credential = _MockUserCredential();
      final user = _MockUser();
      when(() => user.uid).thenReturn('uid123');
      when(() => user.email).thenReturn('test@example.com');
      when(() => user.displayName).thenReturn('Test');
      when(() => credential.user).thenReturn(user);
      when(() => auth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => credential);
      when(() => userRepo.ensureUserProfileExists(uid: any(named: 'uid'), email: any(named: 'email'), displayName: any(named: 'displayName')))
          .thenAnswer((_) async {});
      when(() => userRepo.saveUserProfile(uid: any(named: 'uid'), email: any(named: 'email'), displayName: any(named: 'displayName')))
          .thenAnswer((_) async {});

      await vm.signInWithPassword(email: 'test@example.com', password: 'pw');

      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
      verify(() => userRepo.ensureUserProfileExists(uid: 'uid123', email: 'test@example.com', displayName: 'Test')).called(1);
      verify(() => userRepo.saveUserProfile(uid: 'uid123', email: 'test@example.com', displayName: 'Test')).called(1);
    });

    test('invalid-email sets friendly error', () async {
      when(() => auth.signInWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(FirebaseAuthException(code: 'invalid-email'));

      await vm.signInWithPassword(email: 'bad', password: 'pw');

      expect(vm.errorMessage, 'The email address is not valid.');
      expect(vm.isLoading, isFalse);
    });
  });

  // Google sign-in tests deferred due to complexity of mocking GoogleSignIn.
}
