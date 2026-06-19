import '../../../core/api/api_parsers.dart';

class AdminUserSummary {
  const AdminUserSummary({
    required this.id,
    required this.displayName,
    this.email,
    this.roles = const [],
    this.permissions = const [],
    this.status,
    this.statusLabel,
    this.createdAt,
    this.lastLoginAt,
  });

  final String id;
  final String displayName;
  final String? email;
  final List<String> roles;
  final List<String> permissions;
  final String? status;
  final String? statusLabel;
  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  String get roleLabel {
    if (roles.isEmpty) {
      return 'No roles returned';
    }
    return roles.join(', ');
  }

  String get permissionCountLabel {
    final count = permissions.length;
    return count == 1 ? '1 permission' : '$count permissions';
  }

  String get safeStatusLabel {
    final label = statusLabel ?? status;
    if (label == null || label.trim().isEmpty) {
      return 'Status not returned';
    }
    return label.trim();
  }

  static AdminUserSummary? fromApi(Object? value) {
    final data = asObjectMap(value);
    if (data.isEmpty) {
      return null;
    }

    final id = _stringValue(data, const ['id', 'uuid', 'user_id']);
    final email = stringFrom(data, const ['email']);
    final displayName =
        stringFrom(data, const ['display_name', 'name', 'full_name']) ?? email;

    if ((id == null || id.isEmpty) &&
        (displayName == null || displayName.isEmpty)) {
      return null;
    }

    return AdminUserSummary(
      id: id ?? displayName!,
      displayName: displayName ?? 'User ${id!}',
      email: email,
      roles: stringListFrom(data, const ['roles']),
      permissions: stringListFrom(data, const ['permissions']),
      status: stringFrom(data, const ['status', 'account_status']),
      statusLabel: stringFrom(data, const [
        'status_label',
        'account_status_label',
      ]),
      createdAt: dateTimeFrom(data, const ['created_at', 'createdAt']),
      lastLoginAt: dateTimeFrom(data, const ['last_login_at', 'last_seen_at']),
    );
  }

  static List<AdminUserSummary> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(AdminUserSummary.fromApi)
        .whereType<AdminUserSummary>()
        .toList(growable: false);
  }
}

String? _stringValue(Map<String, Object?> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is num) {
      return value.toString();
    }
  }
  return null;
}
