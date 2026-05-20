class AuthSession {
  const AuthSession({
    required this.accessToken,
    this.email,
    this.displayName,
    this.roles = const [],
    this.permissions = const [],
    this.tokenExpiresAt,
  });

  final String accessToken;
  final String? email;
  final String? displayName;
  final List<String> roles;
  final List<String> permissions;
  final DateTime? tokenExpiresAt;

  bool get isExpired {
    final expiry = tokenExpiresAt;
    if (expiry == null) {
      return false;
    }

    return !expiry.isAfter(DateTime.now());
  }

  bool get canAccessReviewWorkflow {
    const allowedRoles = {
      'peer_reviewer',
      'curator',
      'expert_validator',
      'admin',
    };

    return roles.any(allowedRoles.contains) ||
        permissions.contains('review.contributions');
  }

  String get roleLabel {
    if (roles.isEmpty) {
      return 'No backend roles returned';
    }

    return roles.join(', ');
  }

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
