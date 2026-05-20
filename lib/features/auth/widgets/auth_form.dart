import 'package:flutter/material.dart';

typedef AuthFormSubmit =
    void Function({
      required String email,
      required String password,
      String? name,
    });

enum AuthFormMode { signIn, register }

class AuthForm extends StatefulWidget {
  const AuthForm({
    super.key,
    required this.onSubmit,
    this.mode = AuthFormMode.signIn,
    this.isLoading = false,
    this.errorMessage,
  });

  final AuthFormSubmit onSubmit;
  final AuthFormMode mode;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.errorMessage;
    final isRegistering = widget.mode == AuthFormMode.register;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isRegistering) ...[
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_outline),
              ),
              enabled: !widget.isLoading,
              autofillHints: const [AutofillHints.name],
              textInputAction: TextInputAction.next,
              validator: (value) {
                final name = value?.trim() ?? '';
                if (name.isEmpty) {
                  return 'Name is required.';
                }
                if (name.length < 2) {
                  return 'Name is too short.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
          ],
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            enabled: !widget.isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            textInputAction: TextInputAction.next,
            validator: (value) {
              final email = value?.trim() ?? '';
              if (email.isEmpty) {
                return 'Email is required.';
              }
              if (!email.contains('@')) {
                return 'Enter a valid email address.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordController,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            enabled: !widget.isLoading,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            textInputAction: isRegistering
                ? TextInputAction.next
                : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!isRegistering) {
                _submit();
              }
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required.';
              }
              if (isRegistering && value.length < 8) {
                return 'Password must be at least 8 characters.';
              }
              return null;
            },
          ),
          if (isRegistering) ...[
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm password',
                prefixIcon: Icon(Icons.lock_reset_outlined),
              ),
              enabled: !widget.isLoading,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirm your password.';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match.';
                }
                return null;
              },
            ),
          ],
          if (errorMessage != null && errorMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              errorMessage,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.isLoading ? null : _submit,
            icon: widget.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(isRegistering ? Icons.person_add_alt : Icons.login),
            label: Text(_submitLabel(isRegistering)),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    widget.onSubmit(
      email: _emailController.text,
      password: _passwordController.text,
      name: widget.mode == AuthFormMode.register ? _nameController.text : null,
    );
  }

  String _submitLabel(bool isRegistering) {
    if (widget.isLoading) {
      return isRegistering ? 'Creating account...' : 'Signing in...';
    }

    return isRegistering ? 'Create account' : 'Sign in';
  }
}
