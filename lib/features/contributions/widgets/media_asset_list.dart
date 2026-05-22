import 'package:flutter/material.dart';

import '../data/media_asset_model.dart';

class MediaAssetList extends StatelessWidget {
  const MediaAssetList({
    required this.assets,
    this.onRemove,
    this.emptyText = 'No media attachments yet.',
    super.key,
  });

  final List<MediaAssetModel> assets;
  final ValueChanged<MediaAssetModel>? onRemove;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty) {
      return Text(emptyText);
    }

    return Column(
      children: [
        for (final asset in assets)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(asset.mediaType)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                asset.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (asset.description != null) ...[
                                const SizedBox(height: 4),
                                Text(asset.description!),
                              ],
                            ],
                          ),
                        ),
                        if (onRemove != null)
                          IconButton(
                            tooltip: 'Remove media',
                            onPressed: () => onRemove!(asset),
                            icon: const Icon(Icons.delete_outline),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(asset.mediaType.label)),
                        Chip(
                          label: Text('Consent: ${asset.consentStatus.label}'),
                        ),
                        Chip(
                          label: Text('Visibility: ${asset.visibility.label}'),
                        ),
                        if (asset.culturalSensitivity)
                          const Chip(
                            avatar: Icon(Icons.warning_amber_outlined),
                            label: Text('Culturally sensitive'),
                          ),
                      ],
                    ),
                    if (_metadataLines(asset).isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_metadataLines(asset).join('\n')),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  IconData _iconFor(MediaType type) {
    return switch (type) {
      MediaType.image => Icons.image_outlined,
      MediaType.audio => Icons.audio_file_outlined,
      MediaType.video => Icons.video_file_outlined,
      MediaType.document => Icons.description_outlined,
    };
  }

  List<String> _metadataLines(MediaAssetModel asset) {
    return [
      if (asset.credit != null) 'Credit: ${asset.credit}',
      if (asset.license != null) 'License: ${asset.license}',
      if (asset.creator != null) 'Creator: ${asset.creator}',
      if (asset.recordingDate != null) 'Recording date: ${asset.recordingDate}',
      if (asset.recordingPlace != null)
        'Recording place: ${asset.recordingPlace}',
      if (asset.relatedEntityLabel != null)
        'Related entity: ${asset.relatedEntityLabel}',
      if (asset.altText != null) 'Alt text: ${asset.altText}',
    ];
  }
}
