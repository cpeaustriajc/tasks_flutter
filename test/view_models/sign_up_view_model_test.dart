import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tasks_flutter/repository/user_repository.dart';
import 'package:tasks_flutter/view_models/sign_up_view_model.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}
class _MockUserCredential extends Mock implements UserCredential {}
class _MockUser extends Mock implements User {}
class _MockUserRepository extends Mock implements UserRepository {}

void main() {
  group('SignUpViewModel.signUpWithPassword', () {
    late _MockFirebaseAuth auth;
    late _MockUserRepository userRepo;
    late SignUpViewModel vm;
  late bool navigated;

    setUp(() {
      auth = _MockFirebaseAuth();
      userRepo = _MockUserRepository();
  navigated = false;
      vm = SignUpViewModel(
        auth: auth,
        userRepository: userRepo,
        navigateOnSuccess: true,
        onSuccessNavigate: () => navigated = true,
      );
    });

    test('successful sign up persists profile and triggers navigation', () async {
      final credential = _MockUserCredential();
      final user = _MockUser();
      when(() => user.uid).thenReturn('u1');
      when(() => user.email).thenReturn('new@example.com');
      when(() => user.displayName).thenReturn('New');
      when(() => credential.user).thenReturn(user);
      when(() => auth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenAnswer((_) async => credential);
      when(() => userRepo.ensureUserProfileExists(uid: any(named: 'uid'), email: any(named: 'email'), displayName: any(named: 'displayName')))
          .thenAnswer((_) async {});
      when(() => userRepo.saveUserProfile(uid: any(named: 'uid'), email: any(named: 'email'), displayName: any(named: 'displayName')))
          .thenAnswer((_) async {});

      await vm.signUpWithPassword(email: 'new@example.com', password: 'pw');

      expect(vm.errorMessage, isNull);
      expect(vm.isLoading, isFalse);
      expect(navigated, isTrue);
      verify(() => userRepo.saveUserProfile(uid: 'u1', email: 'new@example.com', displayName: 'New')).called(1);
    });

    test('weak-password assigns friendly error', () async {
      when(() => auth.createUserWithEmailAndPassword(email: any(named: 'email'), password: any(named: 'password')))
          .thenThrow(FirebaseAuthException(code: 'weak-password'));

      await vm.signUpWithPassword(email: 'x@y.z', password: 'short');

      expect(vm.errorMessage, 'The password provided is too weak.');
      expect(vm.isLoading, isFalse);
      expect(navigated, isFalse);
    });
  });
}
