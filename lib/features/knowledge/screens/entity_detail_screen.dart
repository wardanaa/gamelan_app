import 'package:flutter/material.dart';

class EntityDetailScreen extends StatelessWidget {
  const EntityDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _EntityDetailAppBar(title: 'Entity details'),
      body: Center(child: Text('Entity details')),
    );
  }
}

class _EntityDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _EntityDetailAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
