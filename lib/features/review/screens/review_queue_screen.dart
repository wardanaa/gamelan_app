import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../contributions/data/contribution_model.dart';
import 'review_detail_screen.dart';

class ReviewQueueScreen extends StatelessWidget {
  const ReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queue = GamelanScope.of(context).reviewQueue;

    return Scaffold(
      appBar: const _ReviewAppBar(title: 'Review queue'),
      body: queue.isEmpty
          ? const Center(child: Text('No submitted contributions need review.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: queue.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
                    child: Text(
                      'Curator demo queue. Review decisions are local and do not publish RDF.',
                    ),
                  );
                }
                final contribution = queue[index - 1];
                return Card(
                  child: ListTile(
                    title: Text(contribution.title),
                    subtitle: Text(
                      '${contribution.knowledgeType} • '
                      '${contribution.gamelanType} • '
                      '${contribution.status.label}',
                    ),
                    trailing: contribution.culturalSensitivity
                        ? const Icon(
                            Icons.warning_amber_outlined,
                            semanticLabel: 'Culturally sensitive',
                          )
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ReviewDetailScreen(
                            contributionId: contribution.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
