import 'package:flutter/material.dart';

class ContributionListScreen extends StatelessWidget {
  const ContributionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ContributionAppBar(title: 'Contributions'),
      body: Center(child: Text('Contribution list')),
    );
  }
}

class _ContributionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
