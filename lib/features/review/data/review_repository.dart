import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/contribution_repository.dart';
import '../../../core/utils/result.dart';
import '../../provenance/data/provenance_timeline_entry.dart';

abstract class ReviewRepository {
  Future<Result<List<ContributionModel>>> fetchReviewQueue();

  Future<Result<List<ProvenanceTimelineEntry>>> fetchReviewProvenance(
    String contributionId,
  );

  Future<Result<void>> approveContribution(String contributionId, String note);

  Future<Result<void>> rejectContribution(String contributionId, String note);

  Future<Result<void>> requestChanges(String contributionId, String note);

  Future<Result<void>> markExpertRequired(
    String contributionId,
    String note,
    List<String> reasons,
  );

  Future<Result<void>> expertValidate(
    String contributionId,
    String decision,
    String note,
    String privateNote,
  );
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
            .map(
              (contribution) => contribution.copyWith(
                allowedActions: const ['approve', 'reject', 'request_revision'],
              ),
            )
            .toList(growable: false),
      ),
      Failure<List<ContributionModel>>(:final message, :final exception) =>
        Failure(message, exception: exception),
    };
  }

  @override
  Future<Result<List<ProvenanceTimelineEntry>>> fetchReviewProvenance(
    String contributionId,
  ) async {
    final contribution = await _contributions.findContribution(contributionId);
    return switch (contribution) {
      Success<ContributionModel?>(:final value) when value != null => Success(
        const <ProvenanceTimelineEntry>[],
      ),
      Success<ContributionModel?>() => const Failure('Contribution not found.'),
      Failure<ContributionModel?>(:final message, :final exception) => Failure(
        message,
        exception: exception,
      ),
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

  @override
  Future<Result<void>> markExpertRequired(
    String contributionId,
    String note,
    List<String> reasons,
  ) async {
    final formattedReasons = reasons
        .map((reason) => reason.trim())
        .where((reason) => reason.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return _contributions.updateContributionStatus(
      contributionId,
      ContributionStatus.expertRequired,
      reviewNote: formattedReasons.isEmpty
          ? note
          : '$note (${formattedReasons.join(', ')})',
    );
  }

  @override
  Future<Result<void>> expertValidate(
    String contributionId,
    String decision,
    String note,
    String privateNote,
  ) async {
    final normalizedDecision = decision.trim().toLowerCase();
    final status = switch (normalizedDecision) {
      'approve' => ContributionStatus.expertApproved,
      'reject' => ContributionStatus.rejected,
      'request_revision' => ContributionStatus.needsRevision,
      _ => ContributionStatus.expertApproved,
    };

    final combinedNote = privateNote.trim().isEmpty
        ? note
        : '$note\nPrivate note: ${privateNote.trim()}';

    return _contributions.updateContributionStatus(
      contributionId,
      status,
      reviewNote: combinedNote,
    );
  }
}
