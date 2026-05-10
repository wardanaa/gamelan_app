import 'package:flutter/material.dart';

class ContributionFormScreen extends StatelessWidget {
  const ContributionFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ContributionFormAppBar(title: 'New contribution'),
      body: Center(child: Text('Contribution form')),
    );
  }
}

class _ContributionFormAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionFormAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
