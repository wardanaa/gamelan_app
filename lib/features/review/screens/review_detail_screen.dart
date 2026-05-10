import 'package:flutter/material.dart';

class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ReviewDetailAppBar(title: 'Review details'),
      body: Center(child: Text('Review details')),
    );
  }
}

class _ReviewDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ReviewDetailAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
