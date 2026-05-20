import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/contributions/data/contribution_draft_storage.dart';
import '../../features/contributions/data/contribution_model.dart';
import '../../features/knowledge/data/knowledge_item.dart';

class GamelanMvpStore extends ChangeNotifier {
  GamelanMvpStore({ContributionDraftStorage? draftStorage})
    : _draftStorage = draftStorage ?? ContributionDraftStorage();

  final ContributionDraftStorage _draftStorage;

  static const knowledgeTypes = <String>[
    'Instrument',
    'Ensemble',
    'Composition',
    'Technique',
    'Person',
    'Group',
    'Place',
    'Term',
    'Media Asset',
    'Source',
  ];

  static const gamelanTypes = <String>['Gong Kebyar', 'Gong Gede'];

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

  final List<KnowledgeItem> _seedKnowledgeItems = const [
    KnowledgeItem(
      id: 'gong-kebyar',
      title: 'Gong Kebyar',
      description:
          'A dynamic Balinese gamelan ensemble style known for sudden contrasts, coordinated interlocking parts, and bright metallophones.',
      knowledgeType: 'Ensemble',
      gamelanType: 'Gong Kebyar',
      relations: ['hasInstrument: gangsa', 'hasInstrument: reyong'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
    KnowledgeItem(
      id: 'gong-gede',
      title: 'Gong Gede',
      description:
          'A Balinese gamelan ensemble associated with large ceremonial instrumentation and older repertoire contexts.',
      knowledgeType: 'Ensemble',
      gamelanType: 'Gong Gede',
      relations: ['hasInstrument: gong', 'hasInstrument: kendang'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
    KnowledgeItem(
      id: 'gangsa',
      title: 'Gangsa',
      description:
          'A keyed metallophone commonly used in Gong Kebyar, often supporting fast melodic and interlocking patterns.',
      knowledgeType: 'Instrument',
      gamelanType: 'Gong Kebyar',
      relations: ['usedInEnsemble: Gong Kebyar'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
    KnowledgeItem(
      id: 'reyong',
      title: 'Reyong',
      description:
          'A row of kettle gongs used in Balinese gamelan, including Gong Kebyar ensemble practice.',
      knowledgeType: 'Instrument',
      gamelanType: 'Gong Kebyar',
      relations: ['usedInEnsemble: Gong Kebyar'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
    KnowledgeItem(
      id: 'kendang',
      title: 'Kendang',
      description:
          'A drum used to lead, cue, and shape ensemble performance in Balinese gamelan contexts.',
      knowledgeType: 'Instrument',
      gamelanType: 'Gong Gede',
      relations: ['usedInEnsemble: Gong Gede'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
    KnowledgeItem(
      id: 'ceng-ceng',
      title: 'Ceng-ceng',
      description:
          'A Balinese cymbal instrument that contributes rhythmic energy and accents in gamelan performance.',
      knowledgeType: 'Instrument',
      gamelanType: 'Gong Kebyar',
      relations: ['usedInEnsemble: Gong Kebyar'],
      sourceSummary: 'Seeded MVP reference from project knowledge model.',
      provenanceSummary: 'Demo seed data, not RDF publication.',
      isCommunityApproved: false,
    ),
  ];

  List<ContributionModel> get contributions =>
      List.unmodifiable(_contributions);

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
    notifyListeners();
  }

  List<ContributionModel> get reviewQueue {
    return _contributions
        .where(
          (contribution) =>
              contribution.status == ContributionStatus.submitted ||
              contribution.status == ContributionStatus.underReview,
        )
        .toList(growable: false);
  }

  List<KnowledgeItem> get knowledgeItems {
    final approved = _contributions
        .where(
          (contribution) => contribution.status == ContributionStatus.approved,
        )
        .map(_knowledgeItemFromContribution);
    return List.unmodifiable([..._seedKnowledgeItems, ...approved]);
  }

  Map<ContributionStatus, int> get contributionStatusCounts {
    return {
      for (final status in ContributionStatus.values)
        status: _contributions.where((item) => item.status == status).length,
    };
  }

  List<KnowledgeItem> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return knowledgeItems
        .where((item) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              item.title.toLowerCase().contains(normalizedQuery) ||
              item.description.toLowerCase().contains(normalizedQuery) ||
              item.relations.any(
                (relation) => relation.toLowerCase().contains(normalizedQuery),
              );
          final matchesGamelan =
              gamelanType == null || item.gamelanType == gamelanType;
          final matchesType =
              knowledgeType == null || item.knowledgeType == knowledgeType;
          return matchesQuery && matchesGamelan && matchesType;
        })
        .toList(growable: false);
  }

  Future<ContributionModel> createContribution({
    required String title,
    required String description,
    required String knowledgeType,
    required String gamelanType,
    required String sourceNote,
    required String contributorNote,
    required bool culturalSensitivity,
    required bool consentGiven,
    required bool submitForReview,
  }) async {
    final contribution = ContributionModel(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: title.trim(),
      description: description.trim(),
      status: submitForReview
          ? ContributionStatus.submitted
          : ContributionStatus.draft,
      knowledgeType: knowledgeType,
      gamelanType: gamelanType,
      sourceNote: sourceNote.trim(),
      contributorNote: contributorNote.trim(),
      culturalSensitivity: culturalSensitivity,
      consentGiven: consentGiven,
      createdAt: DateTime.now(),
    );
    _contributions.insert(0, contribution);
    notifyListeners();
    if (contribution.status == ContributionStatus.draft) {
      await _persistDrafts();
    }
    return contribution;
  }

  ContributionModel? contributionById(String id) {
    for (final contribution in _contributions) {
      if (contribution.id == id) {
        return contribution;
      }
    }
    return null;
  }

  KnowledgeItem? knowledgeItemById(String id) {
    for (final item in knowledgeItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  void markUnderReview(String id) {
    _updateContributionStatus(id, ContributionStatus.underReview);
  }

  void approveContribution(String id, String note) {
    _updateContributionStatus(id, ContributionStatus.approved, note);
  }

  void rejectContribution(String id, String note) {
    _updateContributionStatus(id, ContributionStatus.rejected, note);
  }

  void requestChanges(String id, String note) {
    _updateContributionStatus(
      id,
      ContributionStatus.rejected,
      'Changes requested: $note',
    );
  }

  void _updateContributionStatus(
    String id,
    ContributionStatus status, [
    String? reviewNote,
  ]) {
    final index = _contributions.indexWhere((item) => item.id == id);
    if (index == -1) {
      return;
    }
    _contributions[index] = _contributions[index].copyWith(
      status: status,
      reviewNote: reviewNote,
    );
    unawaited(_persistDrafts());
    notifyListeners();
  }

  Future<void> _persistDrafts() async {
    final drafts = _contributions
        .where(
          (contribution) => contribution.status == ContributionStatus.draft,
        )
        .toList(growable: false);
    await _draftStorage.saveDrafts(drafts);
  }

  KnowledgeItem _knowledgeItemFromContribution(ContributionModel contribution) {
    return KnowledgeItem(
      id: 'approved-${contribution.id}',
      title: contribution.title,
      description: contribution.description,
      knowledgeType: contribution.knowledgeType,
      gamelanType: contribution.gamelanType,
      relations: const ['validatedBy: local curator demo'],
      sourceSummary: contribution.sourceNote,
      provenanceSummary:
          'Community approved demo content. Contributor note: ${contribution.contributorNote}',
      isCommunityApproved: true,
    );
  }
}
