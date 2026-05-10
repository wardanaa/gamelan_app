import 'package:flutter/material.dart';

class ContributionStatusScreen extends StatelessWidget {
  const ContributionStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: _ContributionStatusAppBar(title: 'Contribution status'),
      body: Center(child: Text('Contribution status')),
    );
  }
}

class _ContributionStatusAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _ContributionStatusAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
