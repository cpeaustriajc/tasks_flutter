import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasks_flutter/factory/app_route_factory.dart';
import 'package:tasks_flutter/singleton/app_navigation_singleton.dart';
import 'package:tasks_flutter/view_models/sign_up_view_model.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final SignUpViewModel _signUpViewModel;

  @override
  void initState() {
    super.initState();
    _signUpViewModel = SignUpViewModel();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppNavigationSingleton.instance.pushNamed(AppRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: ListenableBuilder(
        listenable: _signUpViewModel,
        builder: (context, _) {
          final bool isLoading = _signUpViewModel.isLoading;
          final error = _signUpViewModel.errorMessage;
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8.0,
                    children: [
                      if (error != null && error.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(hintText: 'Email'),
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }

                          return null;
                        },
                      ),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(hintText: 'Password'),
                        obscureText: true,
                        validator: (String? value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }

                          return null;
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _signUpViewModel.signUpWithPassword(
                                  email: _emailController.text.trim(),
                                  password: _passwordController.text.trim(),
                                );
                              }
                            },
                            child: const Text('Sign Up'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/sign-in');
                  },
                  child: const Text('Already have an account? Sign In'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
