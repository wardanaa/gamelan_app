import '../../../core/utils/result.dart';
import 'admin_user_summary.dart';
import 'audit_log_entry.dart';

abstract class AdminRepository {
  Future<Result<List<AdminUserSummary>>> fetchUsers();

  Future<Result<List<AuditLogEntry>>> fetchAuditLogs();
}

class LocalAdminRepository implements AdminRepository {
  LocalAdminRepository({
    List<AdminUserSummary> users = const [
      AdminUserSummary(
        id: 'local-admin',
        displayName: 'Local Admin',
        email: 'admin@example.com',
        roles: ['admin'],
        permissions: ['admin.users.view', 'admin.audit_logs.view'],
        status: 'active',
        statusLabel: 'Active',
      ),
      AdminUserSummary(
        id: 'local-curator',
        displayName: 'Local Curator',
        email: 'curator@example.com',
        roles: ['curator'],
        permissions: ['review.contributions'],
        status: 'active',
        statusLabel: 'Active',
      ),
    ],
    List<AuditLogEntry> auditLogs = const [
      AuditLogEntry(
        id: 'audit-1',
        eventType: 'admin_viewed_users',
        summary: 'Admin user list viewed.',
        actorLabel: 'Local Admin',
        targetType: 'Admin',
      ),
      AuditLogEntry(
        id: 'audit-2',
        eventType: 'review_decision_recorded',
        summary: 'Review decision recorded by backend.',
        targetType: 'Contribution',
        targetId: 'local-contribution',
      ),
    ],
  }) : _users = users,
       _auditLogs = auditLogs;

  final List<AdminUserSummary> _users;
  final List<AuditLogEntry> _auditLogs;

  @override
  Future<Result<List<AuditLogEntry>>> fetchAuditLogs() async {
    return Success(List.unmodifiable(_auditLogs));
  }

  @override
  Future<Result<List<AdminUserSummary>>> fetchUsers() async {
    return Success(List.unmodifiable(_users));
  }
}
