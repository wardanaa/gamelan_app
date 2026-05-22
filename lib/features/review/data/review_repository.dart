import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/contribution_repository.dart';

abstract class ReviewRepository {
  Future<List<ContributionModel>> fetchReviewQueue();

  Future<void> markUnderReview(String contributionId);

  Future<void> approveContribution(String contributionId, String note);

  Future<void> rejectContribution(String contributionId, String note);

  Future<void> requestChanges(String contributionId, String note);
}

class LocalReviewRepository implements ReviewRepository {
  const LocalReviewRepository({required ContributionRepository contributions})
    : _contributions = contributions;

  final ContributionRepository _contributions;

  @override
  Future<List<ContributionModel>> fetchReviewQueue() async {
    final contributions = await _contributions.fetchContributions();
    return contributions
        .where(
          (contribution) =>
              contribution.status == ContributionStatus.submitted ||
              contribution.status == ContributionStatus.underReview,
        )
        .toList(growable: false);
  }

  @override
  Future<void> markUnderReview(String contributionId) async {
    await _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.underReview,
    );
  }

  @override
  Future<void> approveContribution(String contributionId, String note) async {
    await _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.approved,
      reviewNote: note,
    );
  }

  @override
  Future<void> rejectContribution(String contributionId, String note) async {
    await _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.rejected,
      reviewNote: note,
    );
  }

  @override
  Future<void> requestChanges(String contributionId, String note) async {
    await _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.rejected,
      reviewNote: 'Changes requested: $note',
    );
  }
}
