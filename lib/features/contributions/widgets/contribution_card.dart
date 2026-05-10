import 'package:flutter/material.dart';

import '../data/contribution_model.dart';

class ContributionCard extends StatelessWidget {
  const ContributionCard({required this.contribution, super.key});

  final ContributionModel contribution;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(contribution.title),
      subtitle: Text(contribution.description),
      trailing: Text(contribution.status.name),
    );
  }
}
