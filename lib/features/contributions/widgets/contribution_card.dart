import 'package:flutter/material.dart';

import '../data/contribution_model.dart';

class ContributionCard extends StatelessWidget {
  const ContributionCard({required this.contribution, this.onTap, super.key});

  final ContributionModel contribution;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(contribution.title),
        subtitle: Text(
          '${contribution.knowledgeType} • ${contribution.gamelanType}\n'
          '${contribution.description}',
        ),
        isThreeLine: true,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(contribution.statusDisplayLabel),
            if (contribution.culturalSensitivity)
              const Icon(
                Icons.warning_amber_outlined,
                semanticLabel: 'Sensitive',
              ),
          ],
        ),
      ),
    );
  }
}
