import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/contribution_repository.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import 'knowledge_item.dart';
import 'knowledge_repository.dart';

class LocalKnowledgeRepository implements KnowledgeRepository {
  const LocalKnowledgeRepository({
    required LocalContributionRepository contributions,
  }) : _contributions = contributions;

  final LocalContributionRepository _contributions;

  static const seedKnowledgeItems = <KnowledgeItem>[
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

  @override
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems() async {
    final contributionsResult = await _contributions.fetchContributions();
    return switch (contributionsResult) {
      Success<List<ContributionModel>>(:final value) => Success(
        List.unmodifiable([
          ...seedKnowledgeItems,
          ...value
              .where(
                (contribution) =>
                    contribution.status == ContributionStatus.curatorApproved ||
                    contribution.status == ContributionStatus.published,
              )
              .map(_knowledgeItemFromContribution),
        ]),
      ),
      Failure<List<ContributionModel>>(:final message, :final exception) =>
        Failure(message, exception: exception),
    };
  }

  @override
  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id) async {
    final itemsResult = await fetchKnowledgeItems();
    return switch (itemsResult) {
      Success<List<KnowledgeItem>>(:final value) => Success(
        () {
          for (final item in value) {
            if (item.id == id) {
              return item;
            }
          }
          return null;
        }(),
      ),
      Failure<List<KnowledgeItem>>(:final message, :final exception) => Failure(
        message,
        exception: exception,
      ),
    };
  }

  @override
  Future<Result<List<KnowledgeItem>>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  }) async {
    final itemsResult = await fetchKnowledgeItems();
    return switch (itemsResult) {
      Success<List<KnowledgeItem>>(:final value) => Success(
        value
            .where((item) {
              final normalizedQuery = query.trim().toLowerCase();
              final matchesQuery =
                  normalizedQuery.isEmpty ||
                  item.title.toLowerCase().contains(normalizedQuery) ||
                  item.description.toLowerCase().contains(normalizedQuery) ||
                  item.relations.any(
                    (relation) =>
                        relation.toLowerCase().contains(normalizedQuery),
                  );
              final matchesGamelan =
                  gamelanType == null || item.gamelanType == gamelanType;
              final matchesType =
                  knowledgeType == null || item.knowledgeType == knowledgeType;
              return matchesQuery && matchesGamelan && matchesType;
            })
            .toList(growable: false),
      ),
      Failure<List<KnowledgeItem>>(:final message, :final exception) => Failure(
        message,
        exception: exception,
      ),
    };
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes() async {
    return const Success(TaxonomyMapper.defaultKnowledgeTypes);
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes() async {
    return const Success(TaxonomyMapper.defaultGamelanTypes);
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
