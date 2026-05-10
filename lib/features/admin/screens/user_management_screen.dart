import 'package:flutter/material.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _UserManagementAppBar(title: 'User management'),
      body: Center(child: Text('User management')),
    );
  }
}

class _UserManagementAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _UserManagementAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
