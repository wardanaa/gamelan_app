import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../contributions/data/contribution_model.dart';
import 'review_decision_screen.dart';

class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({required this.contributionId, super.key});

  final String contributionId;

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);
    final contribution = store.contributionById(contributionId);

    if (contribution == null) {
      return const Scaffold(
        appBar: _ReviewDetailAppBar(title: 'Review details'),
        body: Center(child: Text('Contribution not found.')),
      );
    }

    return Scaffold(
      appBar: const _ReviewDetailAppBar(title: 'Review details'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            contribution.title,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(contribution.status.label)),
              Chip(label: Text(contribution.knowledgeType)),
              Chip(label: Text(contribution.gamelanType)),
              if (contribution.culturalSensitivity)
                const Chip(
                  avatar: Icon(Icons.warning_amber_outlined),
                  label: Text('Culturally sensitive'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _ReviewSection(title: 'Description', body: contribution.description),
          _ReviewSection(title: 'Source note', body: contribution.sourceNote),
          _ReviewSection(
            title: 'Contributor note',
            body: contribution.contributorNote.isEmpty
                ? 'No contributor note.'
                : contribution.contributorNote,
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'AI triage is not implemented. Curator decisions here are local demo actions only.',
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (contribution.status == ContributionStatus.submitted)
            OutlinedButton.icon(
              onPressed: () async {
                await store.markUnderReview(contribution.id);
              },
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Mark under review'),
            ),
          FilledButton.icon(
            onPressed: () => _openDecision(
              context,
              ReviewDecisionAction.approve,
              contribution.id,
            ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Approve'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openDecision(
              context,
              ReviewDecisionAction.requestChanges,
              contribution.id,
            ),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Request changes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _openDecision(
              context,
              ReviewDecisionAction.reject,
              contribution.id,
            ),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _openDecision(
    BuildContext context,
    ReviewDecisionAction action,
    String contributionId,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ReviewDecisionScreen(
          action: action,
          contributionId: contributionId,
        ),
      ),
    );
  }
}

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(body),
        ],
      ),
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
