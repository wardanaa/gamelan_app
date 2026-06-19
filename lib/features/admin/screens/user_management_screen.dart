import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../data/admin_user_summary.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final _searchController = TextEditingController();
  List<AdminUserSummary> _users = const [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUsers();
    });
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = _filteredUsers();

    return Scaffold(
      appBar: AppBar(
        title: const Text('User management'),
        actions: [
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _isLoading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Search users',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _AdminStateMessage(
                icon: Icons.hourglass_empty,
                title: 'Loading users',
                message: 'Fetching the backend admin user list.',
                showProgress: true,
              )
            else if (_errorMessage != null)
              _AdminStateMessage(
                icon: Icons.lock_outline,
                title: 'Admin users unavailable',
                message: _errorMessage!,
              )
            else if (_users.isEmpty)
              const _AdminStateMessage(
                icon: Icons.people_outline,
                title: 'No users returned',
                message: 'The backend returned an empty admin user list.',
              )
            else if (visibleUsers.isEmpty)
              const _AdminStateMessage(
                icon: Icons.search_off,
                title: 'No matching users',
                message: 'Try a different name, email, role, or status.',
              )
            else ...[
              Text(
                '${visibleUsers.length} users',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final user in visibleUsers) _AdminUserCard(user: user),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await GamelanScope.of(context).fetchAdminUsers();
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success<List<AdminUserSummary>>(:final value):
        setState(() {
          _users = value;
          _isLoading = false;
        });
      case Failure<List<AdminUserSummary>>(:final message):
        setState(() {
          _errorMessage = message;
          _isLoading = false;
        });
    }
  }

  List<AdminUserSummary> _filteredUsers() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _users;
    }
    return _users
        .where((user) {
          return user.displayName.toLowerCase().contains(query) ||
              (user.email?.toLowerCase().contains(query) ?? false) ||
              user.roles.any((role) => role.toLowerCase().contains(query)) ||
              user.safeStatusLabel.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _onSearchChanged() {
    setState(() {});
  }
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({required this.user});

  final AdminUserSummary user;

  @override
  Widget build(BuildContext context) {
    final createdAt = _formatDateTime(user.createdAt);
    final lastLoginAt = _formatDateTime(user.lastLoginAt);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Semantics(
                label: 'User account',
                child: const Icon(Icons.person_outline),
              ),
              title: Text(
                user.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                user.email ?? 'Email not returned',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(user.safeStatusLabel),
                ),
                Chip(
                  avatar: const Icon(Icons.badge_outlined, size: 18),
                  label: Text(user.permissionCountLabel),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Roles: ${user.roleLabel}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text('Created: $createdAt'),
            Text('Last login: $lastLoginAt'),
          ],
        ),
      ),
    );
  }
}

class _AdminStateMessage extends StatelessWidget {
  const _AdminStateMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            if (showProgress)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 40),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return 'Not returned';
  }
  final local = value.toLocal();
  final date =
      '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
  final time =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
