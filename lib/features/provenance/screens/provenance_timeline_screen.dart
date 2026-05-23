import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../../core/utils/result.dart';
import '../data/provenance_timeline_entry.dart';

enum ProvenanceTimelineScope { contribution, review }

class ProvenanceTimelineScreen extends StatefulWidget {
  const ProvenanceTimelineScreen.contribution({
    required this.contributionId,
    required this.subjectTitle,
    super.key,
  }) : scope = ProvenanceTimelineScope.contribution;

  const ProvenanceTimelineScreen.review({
    required this.contributionId,
    required this.subjectTitle,
    super.key,
  }) : scope = ProvenanceTimelineScope.review;

  final String contributionId;
  final String subjectTitle;
  final ProvenanceTimelineScope scope;

  @override
  State<ProvenanceTimelineScreen> createState() =>
      _ProvenanceTimelineScreenState();
}

class _ProvenanceTimelineScreenState extends State<ProvenanceTimelineScreen> {
  bool _didLoad = false;
  bool _isLoading = true;
  String? _message;
  List<ProvenanceTimelineEntry> _entries = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) {
      return;
    }
    _didLoad = true;
    _loadTimeline();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Provenance timeline')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Only safe trace fields are shown here. Private notes, hidden identities, file paths, URLs, and raw AI content are omitted.',
                        ),
                      ],
                    ),
                  ),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 12),
                  Card(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (_entries.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'No provenance timeline entries are available yet.',
                    ),
                  )
                else
                  ..._buildTimeline(context),
              ],
            ),
    );
  }

  List<Widget> _buildTimeline(BuildContext context) {
    final entries = [..._entries]
      ..sort((a, b) {
        final left = a.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.occurredAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return [
      for (var index = 0; index < entries.length; index++) ...[
        _TimelineEntryCard(entry: entries[index]),
        if (index < entries.length - 1) const SizedBox(height: 12),
      ],
    ];
  }

  Future<void> _loadTimeline() async {
    final store = GamelanScope.of(context);
    final requests = switch (widget.scope) {
      ProvenanceTimelineScope.contribution =>
        <Future<Result<List<ProvenanceTimelineEntry>>>>[
          store.fetchContributionVersions(widget.contributionId),
          store.fetchContributionProvenance(widget.contributionId),
        ],
      ProvenanceTimelineScope.review =>
        <Future<Result<List<ProvenanceTimelineEntry>>>>[
          store.fetchReviewProvenance(widget.contributionId),
        ],
    };

    final results = await Future.wait(requests);
    final entries = <ProvenanceTimelineEntry>[];
    final messages = <String>[];

    for (final result in results) {
      switch (result) {
        case Success<List<ProvenanceTimelineEntry>>(:final value):
          entries.addAll(value);
        case Failure<List<ProvenanceTimelineEntry>>(:final message):
          messages.add(message);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _entries = entries;
      _isLoading = false;
      _message = messages.isEmpty
          ? null
          : messages.length == results.length && entries.isEmpty
          ? 'Trace data is unavailable right now.'
          : 'Some trace data could not be loaded.';
    });
  }
}

class _TimelineEntryCard extends StatelessWidget {
  const _TimelineEntryCard({required this.entry});

  final ProvenanceTimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.kindLabel, style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(entry.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(entry.summary),
            const SizedBox(height: 12),
            _SafeRow(
              label: 'When',
              value:
                  _formatDate(context, entry.occurredAt) ?? 'Time unavailable',
            ),
            _SafeRow(label: 'Actor', value: entry.safeActorLabel),
            _SafeRow(label: 'Event type', value: entry.eventType),
            if (entry.metadata.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Safe metadata', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final field in entry.metadata)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${field.label}: ${field.value}'),
                ),
            ],
          ],
        ),
      ),
    );
  }

  String? _formatDate(BuildContext context, DateTime? value) {
    if (value == null) {
      return null;
    }
    return MaterialLocalizations.of(context).formatFullDate(value);
  }
}

class _SafeRow extends StatelessWidget {
  const _SafeRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
