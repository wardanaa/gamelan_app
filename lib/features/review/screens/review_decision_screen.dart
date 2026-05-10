import 'package:flutter/material.dart';

class ReviewDecisionScreen extends StatelessWidget {
  const ReviewDecisionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ReviewDecisionAppBar(title: 'Review decision'),
      body: Center(child: Text('Review decision')),
    );
  }
}

class _ReviewDecisionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ReviewDecisionAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
