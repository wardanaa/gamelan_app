import 'package:flutter/material.dart';

import '../data/triage_suggestion.dart';

class AiTriageSummary extends StatelessWidget {
  const AiTriageSummary({required this.suggestion, super.key});

  final TriageSuggestion suggestion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(suggestion.label, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'AI triage is a reviewer aid only. It never validates or publishes content.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TriageChip(label: 'Provider: ${suggestion.provider}'),
                _TriageChip(label: 'Model: ${suggestion.modelName}'),
                if (suggestion.confidenceScore != null)
                  _TriageChip(
                    label: 'Confidence: ${suggestion.confidenceScore}',
                  ),
                if (suggestion.suggestedEntityType != null)
                  _TriageChip(
                    label: 'Suggested type: ${suggestion.suggestedEntityType}',
                  ),
              ],
            ),
            if (suggestion.curatorSummary != null &&
                suggestion.curatorSummary!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                suggestion.curatorSummary!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
            if (suggestion.uncertaintyNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Uncertainty notes', style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final note in suggestion.uncertaintyNotes)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('- $note'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TriageChip extends StatelessWidget {
  const _TriageChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(label),
      ),
    );
  }
}
