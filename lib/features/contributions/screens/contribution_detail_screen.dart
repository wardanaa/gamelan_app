import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../data/contribution_model.dart';

class ContributionDetailScreen extends StatelessWidget {
  const ContributionDetailScreen({required this.contributionId, super.key});

  final String contributionId;

  @override
  Widget build(BuildContext context) {
    final contribution = GamelanScope.of(
      context,
    ).contributionById(contributionId);

    if (contribution == null) {
      return const Scaffold(
        appBar: _ContributionDetailAppBar(title: 'Contribution details'),
        body: Center(child: Text('Contribution not found.')),
      );
    }

    return Scaffold(
      appBar: const _ContributionDetailAppBar(title: 'Contribution details'),
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
              Chip(label: Text(contribution.statusDisplayLabel)),
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
          _DetailSection(title: 'Description', body: contribution.description),
          _DetailSection(title: 'Source note', body: contribution.sourceNote),
          _DetailSection(
            title: 'Contributor note',
            body: contribution.contributorNote.isEmpty
                ? 'No contributor note.'
                : contribution.contributorNote,
          ),
          _DetailSection(
            title: 'Consent',
            body: contribution.consentGiven
                ? 'Contributor consent confirmed.'
                : 'Consent has not been confirmed.',
          ),
          if (contribution.reviewNote != null)
            _DetailSection(
              title: 'Review note',
              body: contribution.reviewNote!,
            ),
          const _BoundaryNotice(),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.body});

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

class _BoundaryNotice extends StatelessWidget {
  const _BoundaryNotice();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Only published knowledge appears in public browsing. '
          'This app does not publish RDF directly or bypass curator review.',
        ),
      ),
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
