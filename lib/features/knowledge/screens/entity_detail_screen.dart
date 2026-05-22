import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../contributions/widgets/media_asset_list.dart';

class EntityDetailScreen extends StatelessWidget {
  const EntityDetailScreen({required this.itemId, super.key});

  final String itemId;

  @override
  Widget build(BuildContext context) {
    final item = GamelanScope.of(context).knowledgeItemById(itemId);

    if (item == null) {
      return const Scaffold(
        appBar: _EntityDetailAppBar(title: 'Knowledge details'),
        body: Center(child: Text('Knowledge item not found.')),
      );
    }

    return Scaffold(
      appBar: const _EntityDetailAppBar(title: 'Knowledge details'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text(item.knowledgeType)),
              Chip(label: Text(item.gamelanType)),
              if (item.isCommunityApproved)
                const Chip(
                  avatar: Icon(Icons.verified_outlined),
                  label: Text('Community approved demo content'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(title: 'Description', body: item.description),
          _DetailSection(title: 'Relations', body: item.relations.join('\n')),
          _DetailSection(title: 'Source', body: item.sourceSummary),
          _DetailSection(title: 'Provenance', body: item.provenanceSummary),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Public media metadata',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                MediaAssetList(
                  assets: item.mediaAssets,
                  emptyText: 'No public media metadata is available.',
                ),
              ],
            ),
          ),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'This MVP does not generate RDF triples or query SPARQL. '
                'These records are local display data only.',
              ),
            ),
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

class _EntityDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const _EntityDetailAppBar({required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: Text(title));
  }
}
