import 'package:flutter/foundation.dart';

import '../../features/contributions/data/contribution_model.dart';
import '../../features/contributions/data/contribution_repository.dart';
import '../../features/knowledge/data/knowledge_item.dart';
import '../../features/knowledge/data/knowledge_repository.dart';
import '../../features/review/data/review_repository.dart';

class GamelanMvpStore extends ChangeNotifier {
  factory GamelanMvpStore({
    ContributionRepository? contributionRepository,
    ReviewRepository? reviewRepository,
    KnowledgeRepository? knowledgeRepository,
  }) {
    final contributions =
        contributionRepository ?? LocalContributionRepository();
    return GamelanMvpStore._(
      contributionRepository: contributions,
      reviewRepository:
          reviewRepository ??
          LocalReviewRepository(contributions: contributions),
      knowledgeRepository:
          knowledgeRepository ??
          LocalKnowledgeRepository(contributions: contributions),
    );
  }

  GamelanMvpStore._({
    required ContributionRepository contributionRepository,
    required ReviewRepository reviewRepository,
    required KnowledgeRepository knowledgeRepository,
  }) : _contributionRepository = contributionRepository,
       _reviewRepository = reviewRepository,
       _knowledgeRepository = knowledgeRepository;

  final ContributionRepository _contributionRepository;
  final ReviewRepository _reviewRepository;
  final KnowledgeRepository _knowledgeRepository;

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

  List<ContributionModel> _contributions = const [];
  List<ContributionModel> _reviewQueue = const [];
  List<KnowledgeItem> _knowledgeItems = const [];
  Map<ContributionStatus, int> _contributionStatusCounts = {
    for (final status in ContributionStatus.values) status: 0,
  };

  List<ContributionModel> get contributions =>
      List.unmodifiable(_contributions);

  List<ContributionModel> get reviewQueue => List.unmodifiable(_reviewQueue);

  List<KnowledgeItem> get knowledgeItems => List.unmodifiable(_knowledgeItems);

  Map<ContributionStatus, int> get contributionStatusCounts =>
      Map.unmodifiable(_contributionStatusCounts);

  Future<void> loadRepositoryState() async {
    await _contributionRepository.loadPersistedDrafts();
    await _refreshState();
  }

  List<KnowledgeItem> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    return _knowledgeItems
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
    final contribution = await _contributionRepository.createContribution(
      ContributionInput(
        title: title,
        description: description,
        knowledgeType: knowledgeType,
        gamelanType: gamelanType,
        sourceNote: sourceNote,
        contributorNote: contributorNote,
        culturalSensitivity: culturalSensitivity,
        consentGiven: consentGiven,
        submitForReview: submitForReview,
      ),
    );
    await _refreshState();
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
    for (final item in _knowledgeItems) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<void> markUnderReview(String id) async {
    await _reviewRepository.markUnderReview(id);
    await _refreshState();
  }

  Future<void> approveContribution(String id, String note) async {
    await _reviewRepository.approveContribution(id, note);
    await _refreshState();
  }

  Future<void> rejectContribution(String id, String note) async {
    await _reviewRepository.rejectContribution(id, note);
    await _refreshState();
  }

  Future<void> requestChanges(String id, String note) async {
    await _reviewRepository.requestChanges(id, note);
    await _refreshState();
  }

  Future<void> _refreshState() async {
    _contributions = await _contributionRepository.fetchContributions();
    _reviewQueue = await _reviewRepository.fetchReviewQueue();
    _knowledgeItems = await _knowledgeRepository.fetchKnowledgeItems();
    _contributionStatusCounts = await _contributionRepository
        .fetchStatusCounts();
    notifyListeners();
  }
}
