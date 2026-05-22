import 'contribution_draft_storage.dart';
import 'contribution_model.dart';

abstract class ContributionRepository {
  Future<void> loadPersistedDrafts();

  Future<List<ContributionModel>> fetchContributions();

  Future<ContributionModel?> findContribution(String id);

  Future<Map<ContributionStatus, int>> fetchStatusCounts();

  Future<ContributionModel> createContribution(ContributionInput input);

  Future<void> updateContributionStatus(
    String id,
    ContributionStatus status, {
    String? reviewNote,
  });
}

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
  Future<List<ContributionModel>> fetchContributions() async {
    return List.unmodifiable(_contributions);
  }

  @override
  Future<ContributionModel?> findContribution(String id) async {
    for (final contribution in _contributions) {
      if (contribution.id == id) {
        return contribution;
      }
    }
    return null;
  }

  @override
  Future<Map<ContributionStatus, int>> fetchStatusCounts() async {
    return {
      for (final status in ContributionStatus.values)
        status: _contributions.where((item) => item.status == status).length,
    };
  }

  @override
  Future<ContributionModel> createContribution(ContributionInput input) async {
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
    );
    _contributions.insert(0, contribution);
    if (contribution.status == ContributionStatus.draft) {
      await _persistDrafts();
    }
    return contribution;
  }

  @override
  Future<void> updateContributionStatus(
    String id,
    ContributionStatus status, {
    String? reviewNote,
  }) async {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }

    _contributions[index] = _contributions[index].copyWith(
      status: status,
      reviewNote: reviewNote,
    );
    await _persistDrafts();
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
