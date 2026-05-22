import '../../../core/utils/result.dart';
import 'contribution_draft_storage.dart';
import 'contribution_model.dart';
import 'media_asset_model.dart';

class ContributionInput {
  const ContributionInput({
    required this.title,
    required this.description,
    required this.knowledgeType,
    required this.gamelanType,
    required this.sourceNote,
    required this.contributorNote,
    required this.culturalSensitivity,
    required this.consentGiven,
    required this.submitForReview,
    this.contributionIntent,
    this.knowledgeTypeSlug,
    this.gamelanTypeSlug,
  });

  final String title;
  final String description;
  final String knowledgeType;
  final String gamelanType;
  final String sourceNote;
  final String contributorNote;
  final bool culturalSensitivity;
  final bool consentGiven;
  final bool submitForReview;
  final String? contributionIntent;
  final String? knowledgeTypeSlug;
  final String? gamelanTypeSlug;
}

abstract class ContributionRepository {
  Future<void> loadPersistedDrafts();

  Future<Result<List<ContributionModel>>> fetchContributions();

  Future<Result<ContributionModel?>> findContribution(String id);

  Future<Result<Map<ContributionStatus, int>>> fetchStatusCounts();

  Future<Result<ContributionModel>> createContribution(ContributionInput input);

  Future<Result<ContributionModel>> updateContribution(
    String id,
    ContributionInput input, {
    DateTime? lastKnownUpdatedAt,
  });

  Future<Result<ContributionModel>> submitContribution(String id);

  Future<Result<void>> archiveContribution(String id);

  Future<Result<MediaAssetModel>> uploadMedia(
    String contributionId,
    MediaUploadInput input,
  );

  Future<Result<void>> removeMedia(String contributionId, String mediaAssetId);
}

class LocalContributionRepository implements ContributionRepository {
  LocalContributionRepository({ContributionDraftStorage? draftStorage})
    : _draftStorage = draftStorage ?? ContributionDraftStorage();

  final ContributionDraftStorage _draftStorage;

  final List<ContributionModel> _contributions = [
    ContributionModel(
      id: 'demo-sensitive-source',
      title: 'Ceremonial Gong Gede source note',
      description:
          'A contributor notes that some Gong Gede performance context should be reviewed before public use.',
      status: ContributionStatus.submitted,
      knowledgeType: 'Source',
      gamelanType: 'Gong Gede',
      sourceNote: 'Community observation; details intentionally brief.',
      contributorNote: 'Please let a curator decide what can be public.',
      culturalSensitivity: true,
      consentGiven: true,
      createdAt: DateTime(2026, 5, 20, 9),
    ),
  ];

  @override
  Future<void> loadPersistedDrafts() async {
    final drafts = await _draftStorage.loadDrafts();
    if (drafts.isEmpty) {
      return;
    }

    final draftIds = drafts.map((draft) => draft.id).toSet();
    _contributions.removeWhere((contribution) {
      return draftIds.contains(contribution.id);
    });
    _contributions.insertAll(0, drafts);
  }

  @override
  Future<Result<List<ContributionModel>>> fetchContributions() async {
    return Success(List.unmodifiable(_contributions));
  }

  @override
  Future<Result<ContributionModel?>> findContribution(String id) async {
    for (final contribution in _contributions) {
      if (contribution.id == id) {
        return Success(contribution);
      }
    }
    return const Success(null);
  }

  @override
  Future<Result<Map<ContributionStatus, int>>> fetchStatusCounts() async {
    return Success({
      for (final status in ContributionStatus.values)
        status: _contributions.where((item) => item.status == status).length,
    });
  }

  @override
  Future<Result<ContributionModel>> createContribution(
    ContributionInput input,
  ) async {
    final contribution = ContributionModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: input.title.trim(),
      description: input.description.trim(),
      status: input.submitForReview
          ? ContributionStatus.submitted
          : ContributionStatus.draft,
      knowledgeType: input.knowledgeType,
      gamelanType: input.gamelanType,
      sourceNote: input.sourceNote.trim(),
      contributorNote: input.contributorNote.trim(),
      culturalSensitivity: input.culturalSensitivity,
      consentGiven: input.consentGiven,
      createdAt: DateTime.now(),
      contributionIntent: input.contributionIntent,
      knowledgeTypeSlug: input.knowledgeTypeSlug,
      gamelanTypeSlug: input.gamelanTypeSlug,
      allowedActions: input.submitForReview
          ? const ['view']
          : const ['view', 'edit', 'submit', 'archive'],
    );
    _contributions.insert(0, contribution);
    if (contribution.status == ContributionStatus.draft) {
      await _persistDrafts();
    }
    return Success(contribution);
  }

  @override
  Future<Result<ContributionModel>> updateContribution(
    String id,
    ContributionInput input, {
    DateTime? lastKnownUpdatedAt,
  }) async {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    final updated = _contributions[index].copyWith(
      title: input.title.trim(),
      description: input.description.trim(),
      knowledgeType: input.knowledgeType,
      gamelanType: input.gamelanType,
      sourceNote: input.sourceNote.trim(),
      contributorNote: input.contributorNote.trim(),
      culturalSensitivity: input.culturalSensitivity,
      consentGiven: input.consentGiven,
      contributionIntent: input.contributionIntent,
      updatedAt: DateTime.now(),
    );
    _contributions[index] = updated;
    await _persistDrafts();
    return Success(updated);
  }

  @override
  Future<Result<ContributionModel>> submitContribution(String id) async {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    _contributions[index] = _contributions[index].copyWith(
      status: ContributionStatus.submitted,
      allowedActions: const ['view'],
    );
    await _persistDrafts();
    return Success(_contributions[index]);
  }

  @override
  Future<Result<void>> archiveContribution(String id) async {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    _contributions[index] = _contributions[index].copyWith(
      status: ContributionStatus.archived,
      allowedActions: const ['view'],
    );
    await _persistDrafts();
    return const Success(null);
  }

  @override
  Future<Result<MediaAssetModel>> uploadMedia(
    String contributionId,
    MediaUploadInput input,
  ) async {
    final index = _contributions.indexWhere(
      (item) => item.id == contributionId,
    );
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    final contribution = _contributions[index];
    if (!contribution.canManageMedia) {
      return const Failure('Media can be attached only to editable drafts.');
    }

    final asset = MediaAssetModel(
      id: 'local-media-${DateTime.now().microsecondsSinceEpoch}',
      title: input.title.trim(),
      description: input.description?.trim(),
      mediaType: input.mediaType,
      consentStatus: input.consentStatus,
      visibility: input.visibility,
      culturalSensitivity: input.culturalSensitivity,
      creator: input.creator?.trim(),
      credit: input.credit?.trim(),
      license: input.license?.trim(),
      recordingDate: input.recordingDate?.trim(),
      recordingPlace: input.recordingPlace?.trim(),
      relatedEntityLabel: input.relatedEntityLabel?.trim(),
      altText: input.altText?.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _contributions[index] = contribution.copyWith(
      mediaAssets: [...contribution.mediaAssets, asset],
      updatedAt: DateTime.now(),
    );
    await _persistDrafts();
    return Success(asset);
  }

  @override
  Future<Result<void>> removeMedia(
    String contributionId,
    String mediaAssetId,
  ) async {
    final index = _contributions.indexWhere(
      (item) => item.id == contributionId,
    );
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    final contribution = _contributions[index];
    if (!contribution.canManageMedia) {
      return const Failure('Media can be removed only from editable drafts.');
    }

    _contributions[index] = contribution.copyWith(
      mediaAssets: contribution.mediaAssets
          .where((asset) => asset.id != mediaAssetId)
          .toList(growable: false),
      updatedAt: DateTime.now(),
    );
    await _persistDrafts();
    return const Success(null);
  }

  Future<Result<void>> updateContributionStatus(
    String id,
    ContributionStatus status, {
    String? reviewNote,
  }) async {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return const Failure('Contribution not found.');
    }

    _contributions[index] = _contributions[index].copyWith(
      status: status,
      reviewNote: reviewNote,
    );
    await _persistDrafts();
    return const Success(null);
  }

  Future<void> _persistDrafts() async {
    final drafts = _contributions
        .where(
          (contribution) => contribution.status == ContributionStatus.draft,
        )
        .toList(growable: false);
    await _draftStorage.saveDrafts(drafts);
  }
}
