import 'package:flutter/material.dart';

class EntityListScreen extends StatelessWidget {
  const EntityListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _KnowledgeAppBar(title: 'Knowledge entities'),
      body: Center(child: Text('Entity list')),
    );
  }
}

class _KnowledgeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _KnowledgeAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
