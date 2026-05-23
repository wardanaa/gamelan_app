import 'package:flutter/material.dart';

import '../../../core/state/gamelan_scope.dart';
import '../../contributions/data/contribution_model.dart';
import '../../contributions/widgets/media_asset_list.dart';
import '../../contributions/widgets/status_badge.dart';
import '../../provenance/screens/provenance_timeline_screen.dart';
import '../widgets/ai_triage_summary.dart';
import '../widgets/expert_validation_dialog.dart';
import '../widgets/mark_expert_required_dialog.dart';
import 'review_decision_screen.dart';

class ReviewDetailScreen extends StatelessWidget {
  const ReviewDetailScreen({required this.contributionId, super.key});

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
            appBar: _ReviewDetailAppBar(title: 'Review details'),
            body: Center(child: Text('Contribution not found.')),
          );
        }

        final allowedActions = _allowedActionsFor(contribution);
        final canApprove =
            allowedActions.contains('approve') ||
            allowedActions.contains('recommend_approve');
        final canReject =
            allowedActions.contains('reject') ||
            allowedActions.contains('recommend_reject');
        final canRequestRevision = allowedActions.contains('request_revision');
        final canMarkExpertRequired = allowedActions.contains(
          'mark_expert_required',
        );
        final canExpertValidate = allowedActions.contains('expert_validate');

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
                  StatusBadge(status: contribution.status),
                  Chip(label: Text(contribution.knowledgeType)),
                  Chip(label: Text(contribution.gamelanType)),
                  if (contribution.culturalSensitivity)
                    const Chip(
                      avatar: Icon(Icons.warning_amber_outlined),
                      label: Text('Culturally sensitive'),
                    ),
                ],
              ),
              if (contribution.statusDescription != null) ...[
                const SizedBox(height: 12),
                Text(contribution.statusDescription!),
              ],
              if (contribution.triageSuggestion != null) ...[
                const SizedBox(height: 16),
                AiTriageSummary(suggestion: contribution.triageSuggestion!),
              ],
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () => _openProvenance(context, contribution),
                icon: const Icon(Icons.timeline_outlined),
                label: const Text('View provenance timeline'),
              ),
              const SizedBox(height: 8),
              _ReviewSection(
                title: 'Description',
                body: contribution.description,
              ),
              _ReviewSection(
                title: 'Source note',
                body: contribution.sourceNote,
              ),
              _ReviewSection(
                title: 'Contributor note',
                body: contribution.contributorNote.isEmpty
                    ? 'No contributor note.'
                    : contribution.contributorNote,
              ),
              _ReviewMediaSection(contribution: contribution),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Review actions are enforced by the backend. AI triage suggestions may appear in API responses but are not authoritative.',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (canApprove || canReject || canRequestRevision)
                _ActionGroup(
                  title: 'Standard review',
                  description:
                      'Use the backend decision workflow for approval, rejection, or revision requests.',
                  children: [
                    if (canApprove)
                      FilledButton.icon(
                        onPressed: () => _openDecision(
                          context,
                          ReviewDecisionAction.approve,
                          contribution.id,
                        ),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                      ),
                    if (canApprove) const SizedBox(height: 8),
                    if (canRequestRevision)
                      OutlinedButton.icon(
                        onPressed: () => _openDecision(
                          context,
                          ReviewDecisionAction.requestChanges,
                          contribution.id,
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Request changes'),
                      ),
                    if (canRequestRevision) const SizedBox(height: 8),
                    if (canReject)
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
              if (canMarkExpertRequired || canExpertValidate) ...[
                const SizedBox(height: 12),
                _ActionGroup(
                  title: 'Expert workflow',
                  description:
                      'Expert actions are shown only when allowed by backend workflow metadata.',
                  children: [
                    if (canMarkExpertRequired)
                      OutlinedButton.icon(
                        onPressed: () =>
                            _openMarkExpertRequired(context, contribution.id),
                        icon: const Icon(Icons.shield_outlined),
                        label: const Text('Request Expert Validation'),
                      ),
                    if (canMarkExpertRequired) const SizedBox(height: 8),
                    if (canExpertValidate)
                      FilledButton.icon(
                        onPressed: () =>
                            _openExpertValidation(context, contribution.id),
                        icon: const Icon(Icons.verified_outlined),
                        label: const Text('Validate'),
                      ),
                  ],
                ),
              ],
              if (!canApprove &&
                  !canReject &&
                  !canRequestRevision &&
                  !canMarkExpertRequired &&
                  !canExpertValidate)
                const Text(
                  'No review actions are currently allowed for this contribution.',
                ),
            ],
          ),
        );
      },
    );
  }

  List<String> _allowedActionsFor(ContributionModel contribution) {
    if (contribution.allowedActions.isNotEmpty) {
      return contribution.allowedActions;
    }

    final fallbackActions = <String>[];
    if (contribution.status == ContributionStatus.submitted ||
        contribution.status == ContributionStatus.underReview ||
        contribution.status == ContributionStatus.needsRevision) {
      fallbackActions.addAll(['approve', 'reject', 'request_revision']);
    }
    if ((contribution.status == ContributionStatus.submitted ||
            contribution.status == ContributionStatus.underReview) &&
        contribution.culturalSensitivity) {
      fallbackActions.add('mark_expert_required');
    }
    if (contribution.status == ContributionStatus.expertRequired) {
      fallbackActions.add('expert_validate');
    }
    return fallbackActions;
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

  void _openMarkExpertRequired(BuildContext context, String contributionId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          MarkExpertRequiredDialog(contributionId: contributionId),
    );
  }

  void _openExpertValidation(BuildContext context, String contributionId) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          ExpertValidationDialog(contributionId: contributionId),
    );
  }

  void _openProvenance(BuildContext context, ContributionModel contribution) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ProvenanceTimelineScreen.review(
          contributionId: contribution.id,
          subjectTitle: contribution.title,
        ),
      ),
    );
  }
}

class _ReviewMediaSection extends StatelessWidget {
  const _ReviewMediaSection({required this.contribution});

  final ContributionModel contribution;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media evidence',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          MediaAssetList(
            assets: contribution.mediaAssets,
            emptyText: 'No media evidence is attached.',
          ),
        ],
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

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({
    required this.title,
    required this.description,
    required this.children,
  });

  final String title;
  final String description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(description),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
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
