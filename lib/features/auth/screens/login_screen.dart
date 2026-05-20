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
  AuthFormMode _mode = AuthFormMode.signIn;

  @override
  Widget build(BuildContext context) {
    final isRegistering = _mode == AuthFormMode.register;

    return Scaffold(
      appBar: _AuthAppBar(title: isRegistering ? 'Create account' : 'Sign in'),
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
                  Text(
                    isRegistering
                        ? 'Create a backend account. The app stores only the access token in secure device storage after the backend confirms the profile.'
                        : 'Sign in with a backend account. The app stores only the access token in secure device storage; backend policies decide what this account can access.',
                  ),
                  const SizedBox(height: 24),
                  AuthForm(
                    mode: _mode,
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onSubmit: _submitAuth,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(
                      isRegistering
                          ? 'Already have an account? Sign in'
                          : 'Need an account? Create one',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitAuth({
    required String email,
    required String password,
    String? name,
  }) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = switch (_mode) {
      AuthFormMode.signIn => await widget.authRepository.signIn(
        email: email,
        password: password,
      ),
      AuthFormMode.register => await widget.authRepository.register(
        name: name ?? '',
        email: email,
        password: password,
      ),
    };
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

  void _toggleMode() {
    setState(() {
      _mode = switch (_mode) {
        AuthFormMode.signIn => AuthFormMode.register,
        AuthFormMode.register => AuthFormMode.signIn,
      };
      _errorMessage = null;
    });
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
