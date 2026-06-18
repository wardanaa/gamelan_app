import 'package:flutter/foundation.dart';

import '../../features/contributions/data/contribution_model.dart';
import '../../features/contributions/data/contribution_repository.dart';
import '../../features/contributions/data/media_asset_model.dart';
import '../../features/contributions/data/rdf_publication_model.dart';
import '../../features/knowledge/data/knowledge_item.dart';
import '../../features/knowledge/data/knowledge_repository.dart';
import '../../features/knowledge/data/local_knowledge_repository.dart';
import '../../features/ontology/data/local_ontology_repository.dart';
import '../../features/ontology/data/ontology_class.dart';
import '../../features/ontology/data/ontology_entity_page.dart';
import '../../features/ontology/data/ontology_mapping.dart';
import '../../features/ontology/data/ontology_property.dart';
import '../../features/ontology/data/ontology_repository.dart';
import '../../features/provenance/data/provenance_timeline_entry.dart';
import '../../features/review/data/review_repository.dart';
import '../api/repository_errors.dart';
import '../mapping/taxonomy_mapper.dart';
import '../utils/result.dart';

class GamelanMvpStore extends ChangeNotifier {
  factory GamelanMvpStore.local({TaxonomyMapper? taxonomyMapper}) {
    final contributions = LocalContributionRepository();
    return GamelanMvpStore._(
      contributionRepository: contributions,
      reviewRepository: LocalReviewRepository(contributions: contributions),
      knowledgeRepository: LocalKnowledgeRepository(
        contributions: contributions,
      ),
      ontologyRepository: LocalOntologyRepository(),
      taxonomyMapper: taxonomyMapper ?? TaxonomyMapper(),
    );
  }

  GamelanMvpStore({
    required ContributionRepository contributionRepository,
    required ReviewRepository reviewRepository,
    required KnowledgeRepository knowledgeRepository,
    OntologyRepository? ontologyRepository,
    TaxonomyMapper? taxonomyMapper,
  }) : this._(
         contributionRepository: contributionRepository,
         reviewRepository: reviewRepository,
         knowledgeRepository: knowledgeRepository,
         ontologyRepository: ontologyRepository ?? LocalOntologyRepository(),
         taxonomyMapper: taxonomyMapper ?? TaxonomyMapper(),
       );

  GamelanMvpStore._({
    required ContributionRepository contributionRepository,
    required ReviewRepository reviewRepository,
    required KnowledgeRepository knowledgeRepository,
    required OntologyRepository ontologyRepository,
    required TaxonomyMapper taxonomyMapper,
  }) : _contributionRepository = contributionRepository,
       _reviewRepository = reviewRepository,
       _knowledgeRepository = knowledgeRepository,
       _ontologyRepository = ontologyRepository,
       _taxonomyMapper = taxonomyMapper;

  final ContributionRepository _contributionRepository;
  final ReviewRepository _reviewRepository;
  final KnowledgeRepository _knowledgeRepository;
  final OntologyRepository _ontologyRepository;
  TaxonomyMapper _taxonomyMapper;

  List<ContributionModel> _contributions = const [];
  List<ContributionModel> _reviewQueue = const [];
  List<KnowledgeItem> _knowledgeItems = const [];
  Map<ContributionStatus, int> _contributionStatusCounts = {
    for (final status in ContributionStatus.values) status: 0,
  };
  String? _lastError;
  bool _isLoading = false;
  bool _isSearching = false;
  List<KnowledgeItem> _searchResults = const [];
  String? _searchNotice;
  bool _lastSearchUsedSemantic = false;
  bool _lastSearchFellBackToKeyword = false;

  List<ContributionModel> get contributions =>
      List.unmodifiable(_contributions);

  List<ContributionModel> get reviewQueue => List.unmodifiable(_reviewQueue);

  List<KnowledgeItem> get knowledgeItems => List.unmodifiable(_knowledgeItems);

  List<KnowledgeItem> get searchResults => List.unmodifiable(_searchResults);

  String? get searchNotice => _searchNotice;

  bool get lastSearchUsedSemantic => _lastSearchUsedSemantic;

  bool get lastSearchFellBackToKeyword => _lastSearchFellBackToKeyword;

  Map<ContributionStatus, int> get contributionStatusCounts =>
      Map.unmodifiable(_contributionStatusCounts);

  TaxonomyMapper get taxonomyMapper => _taxonomyMapper;

  List<String> get knowledgeTypeLabels => _taxonomyMapper.knowledgeTypeLabels;

  List<String> get gamelanTypeLabels => _taxonomyMapper.gamelanTypeLabels;

  List<TaxonomyOption> get contributionIntentOptions =>
      TaxonomyMapper.contributionIntents;

  String? get lastError => _lastError;

  bool get isLoading => _isLoading;

  bool get isSearching => _isSearching;

  Future<void> loadRepositoryState() async {
    _setLoading(true);
    await _contributionRepository.loadPersistedDrafts();
    await _loadTaxonomy();
    await _refreshState();
    _setLoading(false);
  }

  Future<List<KnowledgeItem>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
  }) async {
    _isSearching = true;
    _searchNotice = null;
    _lastSearchUsedSemantic = false;
    _lastSearchFellBackToKeyword = false;
    notifyListeners();

    final gamelanSlug = gamelanType == null
        ? null
        : _taxonomyMapper.gamelanSlugFromLabel(gamelanType);
    final knowledgeSlug = knowledgeType == null
        ? null
        : _taxonomyMapper.knowledgeSlugFromLabel(knowledgeType);

    final result = await _knowledgeRepository.searchKnowledge(
      query: query,
      gamelanType: gamelanType,
      knowledgeType: knowledgeType,
      gamelanTypeSlug: gamelanSlug,
      knowledgeTypeSlug: knowledgeSlug,
    );

    _isSearching = false;
    switch (result) {
      case Success<KnowledgeSearchResult>(:final value):
        _searchResults = value.items;
        _searchNotice = value.notice;
        _lastSearchUsedSemantic = value.usedSemanticSearch;
        _lastSearchFellBackToKeyword = value.fellBackToKeyword;
        _lastError = null;
      case Failure<KnowledgeSearchResult>(:final message):
        _searchResults = const [];
        _searchNotice = null;
        _lastSearchUsedSemantic = false;
        _lastSearchFellBackToKeyword = false;
        _lastError = message;
    }
    notifyListeners();
    return _searchResults;
  }

  Future<Result<ContributionModel>> createContribution({
    required String title,
    required String description,
    required String knowledgeType,
    required String gamelanType,
    required String sourceNote,
    required String contributorNote,
    required bool culturalSensitivity,
    required bool consentGiven,
    required bool submitForReview,
    String? contributionIntent,
  }) async {
    final result = await _contributionRepository.createContribution(
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
        contributionIntent: contributionIntent,
        knowledgeTypeSlug: _taxonomyMapper.knowledgeSlugFromLabel(
          knowledgeType,
        ),
        gamelanTypeSlug: _taxonomyMapper.gamelanSlugFromLabel(gamelanType),
      ),
    );

    switch (result) {
      case Success<ContributionModel>(:final value):
        _lastError = null;
        await _refreshState();
        return Success(value);
      case Failure<ContributionModel>(:final message, :final exception):
        _lastError = message;
        notifyListeners();
        return Failure(message, exception: exception);
    }
  }

  Future<Result<ContributionModel>> submitContribution(String id) async {
    final result = await _contributionRepository.submitContribution(id);
    switch (result) {
      case Success<ContributionModel>(:final value):
        _lastError = null;
        await _refreshState();
        return Success(value);
      case Failure<ContributionModel>(:final message, :final exception):
        _lastError = message;
        notifyListeners();
        return Failure(message, exception: exception);
    }
  }

  Future<Result<MediaAssetModel>> uploadContributionMedia(
    String contributionId,
    MediaUploadInput input,
  ) async {
    final result = await _contributionRepository.uploadMedia(
      contributionId,
      input,
    );
    switch (result) {
      case Success<MediaAssetModel>(:final value):
        _lastError = null;
        await _refreshState();
        return Success(value);
      case Failure<MediaAssetModel>(:final message, :final exception):
        _lastError = message;
        notifyListeners();
        return Failure(message, exception: exception);
    }
  }

  Future<Result<void>> removeContributionMedia(
    String contributionId,
    String mediaAssetId,
  ) async {
    final result = await _contributionRepository.removeMedia(
      contributionId,
      mediaAssetId,
    );
    switch (result) {
      case Success<void>():
        _lastError = null;
        await _refreshState();
      case Failure<void>(:final message):
        _lastError = message;
        notifyListeners();
    }
    return result;
  }

  ContributionModel? contributionById(String id) {
    for (final contribution in [..._reviewQueue, ..._contributions]) {
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
    for (final item in _searchResults) {
      if (item.id == id) {
        return item;
      }
    }
    return null;
  }

  Future<Result<void>> approveContribution(String id, String note) async {
    return _runReviewAction(
      () => _reviewRepository.approveContribution(id, note),
    );
  }

  Future<Result<void>> rejectContribution(String id, String note) async {
    return _runReviewAction(
      () => _reviewRepository.rejectContribution(id, note),
    );
  }

  Future<Result<void>> requestChanges(String id, String note) async {
    return _runReviewAction(() => _reviewRepository.requestChanges(id, note));
  }

  Future<Result<void>> markExpertRequired(
    String id,
    String note,
    List<String> reasons,
  ) async {
    return _runReviewAction(
      () => _reviewRepository.markExpertRequired(id, note, reasons),
    );
  }

  Future<Result<void>> expertValidate(
    String id,
    String decision,
    String note,
    String privateNote,
  ) async {
    return _runReviewAction(
      () => _reviewRepository.expertValidate(id, decision, note, privateNote),
    );
  }

  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionVersions(
    String contributionId,
  ) {
    return _contributionRepository.fetchContributionVersions(contributionId);
  }

  Future<Result<List<ProvenanceTimelineEntry>>> fetchContributionProvenance(
    String contributionId,
  ) {
    return _contributionRepository.fetchContributionProvenance(contributionId);
  }

  Future<Result<List<ProvenanceTimelineEntry>>> fetchReviewProvenance(
    String contributionId,
  ) {
    return _reviewRepository.fetchReviewProvenance(contributionId);
  }

  Future<Result<List<OntologyClass>>> getOntologyClasses() {
    return _ontologyRepository.getClasses();
  }

  Future<Result<List<OntologyProperty>>> getOntologyProperties() {
    return _ontologyRepository.getProperties();
  }

  Future<Result<OntologyEntityPage>> getOntologyEntities({
    String? type,
    int page = 1,
    int perPage = 10,
  }) {
    return _ontologyRepository.getEntities(
      type: type,
      page: page,
      perPage: perPage,
    );
  }

  Future<Result<RdfPublicationModel>> queueRdfPublication(
    String contributionId,
    OntologyMapping mapping,
  ) async {
    final result = await _contributionRepository.queueRdfPublication(
      contributionId,
      mapping,
    );
    switch (result) {
      case Success<RdfPublicationModel>():
        _lastError = null;
        await _refreshState();
      case Failure<RdfPublicationModel>(:final message):
        _lastError = message;
        notifyListeners();
    }
    return result;
  }

  Map<String, List<String>>? validationErrorsFromFailure(
    Result<ContributionModel> result,
  ) {
    if (result is! Failure<ContributionModel>) {
      return null;
    }
    final validation = validationExceptionFrom(result.exception);
    return validation?.fieldErrors;
  }

  Map<String, List<String>>? mediaValidationErrorsFromFailure(
    Result<MediaAssetModel> result,
  ) {
    if (result is! Failure<MediaAssetModel>) {
      return null;
    }
    final validation = validationExceptionFrom(result.exception);
    return validation?.fieldErrors;
  }

  void clearLastError() {
    _lastError = null;
    notifyListeners();
  }

  Future<Result<void>> _runReviewAction(
    Future<Result<void>> Function() action,
  ) async {
    final result = await action();
    switch (result) {
      case Success<void>():
        _lastError = null;
        await _refreshState();
      case Failure<void>(:final message):
        _lastError = message;
        notifyListeners();
    }
    return result;
  }

  Future<void> _loadTaxonomy() async {
    final knowledgeTypesResult = await _knowledgeRepository
        .fetchKnowledgeTypes();
    final gamelanTypesResult = await _knowledgeRepository.fetchGamelanTypes();

    final knowledgeTypes = switch (knowledgeTypesResult) {
      Success<List<TaxonomyOption>>(:final value) when value.isNotEmpty =>
        value,
      _ => TaxonomyMapper.defaultKnowledgeTypes,
    };
    final gamelanTypes = switch (gamelanTypesResult) {
      Success<List<TaxonomyOption>>(:final value) when value.isNotEmpty =>
        value,
      _ => TaxonomyMapper.defaultGamelanTypes,
    };

    _taxonomyMapper = TaxonomyMapper(
      knowledgeTypes: knowledgeTypes,
      gamelanTypes: gamelanTypes,
    );
  }

  Future<void> _refreshState() async {
    final contributionsResult = await _contributionRepository
        .fetchContributions();
    final reviewQueueResult = await _reviewRepository.fetchReviewQueue();
    final knowledgeResult = await _knowledgeRepository.fetchKnowledgeItems();
    final statusCountsResult = await _contributionRepository
        .fetchStatusCounts();

    switch (contributionsResult) {
      case Success<List<ContributionModel>>(:final value):
        _contributions = value;
      case Failure<List<ContributionModel>>(:final message):
        _lastError ??= message;
    }

    switch (reviewQueueResult) {
      case Success<List<ContributionModel>>(:final value):
        _reviewQueue = value;
      case Failure<List<ContributionModel>>(:final message):
        _lastError ??= message;
    }

    switch (knowledgeResult) {
      case Success<List<KnowledgeItem>>(:final value):
        _knowledgeItems = value;
      case Failure<List<KnowledgeItem>>(:final message):
        _lastError ??= message;
    }

    switch (statusCountsResult) {
      case Success<Map<ContributionStatus, int>>(:final value):
        _contributionStatusCounts = value;
      case Failure<Map<ContributionStatus, int>>():
        _contributionStatusCounts = {
          for (final status in ContributionStatus.values)
            status: _contributions
                .where((item) => item.status == status)
                .length,
        };
    }

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
