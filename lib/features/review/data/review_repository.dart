import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/contribution_repository.dart';
import '../../../core/utils/result.dart';

abstract class ReviewRepository {
  Future<Result<List<ContributionModel>>> fetchReviewQueue();

  Future<Result<void>> approveContribution(String contributionId, String note);

  Future<Result<void>> rejectContribution(String contributionId, String note);

  Future<Result<void>> requestChanges(String contributionId, String note);
}

class LocalReviewRepository implements ReviewRepository {
  LocalReviewRepository({required LocalContributionRepository contributions})
    : _contributions = contributions;

  final LocalContributionRepository _contributions;

  @override
  Future<Result<List<ContributionModel>>> fetchReviewQueue() async {
    final contributionsResult = await _contributions.fetchContributions();
    return switch (contributionsResult) {
      Success<List<ContributionModel>>(:final value) => Success(
        value
            .where(
              (contribution) =>
                  contribution.status == ContributionStatus.submitted ||
                  contribution.status == ContributionStatus.underReview,
            )
            .toList(growable: false),
      ),
      Failure<List<ContributionModel>>(:final message, :final exception) =>
        Failure(message, exception: exception),
    };
  }

  @override
  Future<Result<void>> approveContribution(
    String contributionId,
    String note,
  ) async {
    return _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.curatorApproved,
      reviewNote: note,
    );
  }

  @override
  Future<Result<void>> rejectContribution(
    String contributionId,
    String note,
  ) async {
    return _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.rejected,
      reviewNote: note,
    );
  }

  @override
  Future<Result<void>> requestChanges(
    String contributionId,
    String note,
  ) async {
    return _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.needsRevision,
      reviewNote: 'Changes requested: $note',
    );
  }
}
