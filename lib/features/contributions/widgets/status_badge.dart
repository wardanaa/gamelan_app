import 'package:flutter/material.dart';

import '../data/contribution_model.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.status,
    this.label,
    this.dense = false,
    super.key,
  });

  final ContributionStatus status;
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final palette = _StatusPalette.forStatus(status, Theme.of(context));
    final text = label ?? status.label;
    final padding = dense
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    final radius = BorderRadius.circular(999);

    return Semantics(
      label: text,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: radius,
          border: Border.all(color: palette.border),
        ),
        child: Padding(
          padding: padding,
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;

  static _StatusPalette forStatus(ContributionStatus status, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return switch (status) {
      ContributionStatus.draft => _StatusPalette(
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
        foreground: colorScheme.onSurfaceVariant,
      ),
      ContributionStatus.submitted => _StatusPalette(
        background: colorScheme.primaryContainer,
        border: colorScheme.primary.withValues(alpha: 0.35),
        foreground: colorScheme.onPrimaryContainer,
      ),
      ContributionStatus.needsRevision => _StatusPalette(
        background: colorScheme.tertiaryContainer,
        border: colorScheme.tertiary.withValues(alpha: 0.35),
        foreground: colorScheme.onTertiaryContainer,
      ),
      ContributionStatus.underReview => _StatusPalette(
        background: colorScheme.secondaryContainer,
        border: colorScheme.secondary.withValues(alpha: 0.35),
        foreground: colorScheme.onSecondaryContainer,
      ),
      ContributionStatus.curatorApproved => _StatusPalette(
        background: Colors.green.shade100,
        border: Colors.green.shade300,
        foreground: Colors.green.shade900,
      ),
      ContributionStatus.expertRequired => _StatusPalette(
        background: Colors.orange.shade100,
        border: Colors.orange.shade300,
        foreground: Colors.orange.shade900,
      ),
      ContributionStatus.expertApproved => _StatusPalette(
        background: Colors.purple.shade100,
        border: Colors.purple.shade300,
        foreground: Colors.purple.shade900,
      ),
      ContributionStatus.published => _StatusPalette(
        background: Colors.teal.shade100,
        border: Colors.teal.shade300,
        foreground: Colors.teal.shade900,
      ),
      ContributionStatus.rejected => _StatusPalette(
        background: colorScheme.errorContainer,
        border: colorScheme.error.withValues(alpha: 0.35),
        foreground: colorScheme.onErrorContainer,
      ),
      ContributionStatus.archived => _StatusPalette(
        background: colorScheme.surfaceContainerHighest,
        border: colorScheme.outlineVariant,
        foreground: colorScheme.onSurfaceVariant,
      ),
    };
  }
}
