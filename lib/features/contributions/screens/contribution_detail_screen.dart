import 'package:flutter/material.dart';

class ContributionDetailScreen extends StatelessWidget {
  const ContributionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ContributionDetailAppBar(title: 'Contribution details'),
      body: Center(child: Text('Contribution details')),
    );
  }
}

class _ContributionDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionDetailAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
