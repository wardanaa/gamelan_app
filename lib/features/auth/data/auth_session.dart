class AuthSession {
  const AuthSession({required this.accessToken, this.email, this.displayName});

  final String accessToken;
  final String? email;
  final String? displayName;

  String get displayLabel {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }

    final userEmail = email?.trim();
    if (userEmail != null && userEmail.isNotEmpty) {
      return userEmail;
    }

    return 'Authenticated user';
  }
}
