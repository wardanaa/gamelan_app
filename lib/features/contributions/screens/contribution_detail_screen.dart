import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../data/contribution_model.dart';
import '../data/media_asset_model.dart';
import '../widgets/media_asset_list.dart';
import 'media_upload_screen.dart';

class ContributionDetailScreen extends StatelessWidget {
  const ContributionDetailScreen({required this.contributionId, super.key});

  final String contributionId;

  @override
  Widget build(BuildContext context) {
    final store = GamelanScope.of(context);

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final contribution = store.contributionById(contributionId);

        if (contribution == null) {
          return const Scaffold(
            appBar: _ContributionDetailAppBar(title: 'Contribution details'),
            body: Center(child: Text('Contribution not found.')),
          );
        }

        return Scaffold(
          appBar: const _ContributionDetailAppBar(
            title: 'Contribution details',
          ),
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
              _DetailSection(
                title: 'Description',
                body: contribution.description,
              ),
              _DetailSection(
                title: 'Source note',
                body: contribution.sourceNote,
              ),
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
              _MediaSection(
                contribution: contribution,
                onAdd: () => _openUpload(context, contribution.id),
                onRemove: (asset) =>
                    _confirmRemove(context, contribution.id, asset),
              ),
              if (contribution.canSubmit) ...[
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => _submitForReview(context, contribution.id),
                  icon: const Icon(Icons.send_outlined),
                  label: const Text('Submit for review'),
                ),
              ],
              const _BoundaryNotice(),
            ],
          ),
        );
      },
    );
  }

  void _openUpload(BuildContext context, String contributionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => MediaUploadScreen(contributionId: contributionId),
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    String contributionId,
    MediaAssetModel asset,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove media?'),
        content: Text('Remove "${asset.title}" from this draft contribution.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }

    final result = await GamelanScope.of(
      context,
    ).removeContributionMedia(contributionId, asset.id);
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success<void>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Media attachment removed.')),
        );
      case Failure<void>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _submitForReview(BuildContext context, String id) async {
    final result = await GamelanScope.of(context).submitContribution(id);
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case Success<ContributionModel>():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contribution submitted for review.')),
        );
      case Failure<ContributionModel>(:final message):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

class _MediaSection extends StatelessWidget {
  const _MediaSection({
    required this.contribution,
    required this.onAdd,
    required this.onRemove,
  });

  final ContributionModel contribution;
  final VoidCallback onAdd;
  final ValueChanged<MediaAssetModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Media attachments',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (contribution.canManageMedia)
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: const Text('Add media'),
                ),
            ],
          ),
          const SizedBox(height: 4),
          MediaAssetList(
            assets: contribution.mediaAssets,
            onRemove: contribution.canManageMedia ? onRemove : null,
          ),
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
