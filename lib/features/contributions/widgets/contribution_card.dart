import 'package:flutter/material.dart';

import '../data/contribution_model.dart';
import 'status_badge.dart';

class ContributionCard extends StatelessWidget {
  const ContributionCard({required this.contribution, this.onTap, super.key});

  final ContributionModel contribution;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Row(
          children: [
            Expanded(
              child: Text(
                contribution.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (contribution.culturalSensitivity) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.warning_amber_outlined,
                size: 20,
                semanticLabel: 'Sensitive content',
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${contribution.knowledgeType} • ${contribution.gamelanType}\n'
          '${contribution.description}',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: StatusBadge(status: contribution.status, dense: true),
      ),
    );
  }
}
