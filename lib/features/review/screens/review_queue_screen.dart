import 'package:flutter/material.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ReviewAppBar(title: 'Review queue'),
      body: Center(child: Text('Review queue')),
    );
  }
}

class _ReviewAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ReviewAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
