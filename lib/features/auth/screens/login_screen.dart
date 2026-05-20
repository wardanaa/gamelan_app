import 'package:flutter/material.dart';

import '../../../core/utils/result.dart';
import '../data/auth_repository.dart';
import '../data/auth_session.dart';
import '../widgets/auth_form.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.authRepository,
    required this.onSignedIn,
  });

  final AuthRepository authRepository;
  final ValueChanged<AuthSession> onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _AuthAppBar(title: 'Sign in'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Gamelan Knowledge',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with a backend account. The app stores only the access token in secure device storage; backend policies decide what this account can access.',
                  ),
                  const SizedBox(height: 24),
                  AuthForm(
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onSubmit: _signIn,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signIn({
    required String email,
    required String password,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.authRepository.signIn(
      email: email,
      password: password,
    );
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<AuthSession>(:final value):
        widget.onSignedIn(value);
      case Failure<AuthSession>(:final message):
        setState(() {
          _isLoading = false;
          _errorMessage = message;
        });
    }
  }
}

class _AuthAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _AuthAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
