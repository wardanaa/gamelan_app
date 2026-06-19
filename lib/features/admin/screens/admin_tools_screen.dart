import 'package:flutter/material.dart';

import 'audit_log_screen.dart';
import 'user_management_screen.dart';

class AdminToolsScreen extends StatelessWidget {
  const AdminToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin tools')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Backend admin', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text(
            'These views are read-only. Backend policies remain the source of truth for every admin record and action.',
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.manage_accounts_outlined),
              title: const Text('User management'),
              subtitle: const Text('View backend-returned users and roles.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const UserManagementScreen(),
                  ),
                );
              },
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: const Text('Audit logs'),
              subtitle: const Text('View safe backend audit summaries.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AuditLogScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
