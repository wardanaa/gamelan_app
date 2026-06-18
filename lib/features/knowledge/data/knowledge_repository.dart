import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import 'knowledge_item.dart';

abstract class KnowledgeRepository {
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems();

  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id);

  Future<Result<KnowledgeSearchResult>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  });

  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes();

  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes();
}

class KnowledgeSearchResult {
  KnowledgeSearchResult({
    required Iterable<KnowledgeItem> items,
    required this.usedSemanticSearch,
    required this.fellBackToKeyword,
    this.notice,
  }) : items = List.unmodifiable(items);

  KnowledgeSearchResult.keyword(Iterable<KnowledgeItem> items)
    : this(items: items, usedSemanticSearch: false, fellBackToKeyword: false);

  KnowledgeSearchResult.semantic(Iterable<KnowledgeItem> items)
    : this(items: items, usedSemanticSearch: true, fellBackToKeyword: false);

  KnowledgeSearchResult.semanticFallback(
    Iterable<KnowledgeItem> items, {
    required String notice,
  }) : this(
         items: items,
         usedSemanticSearch: false,
         fellBackToKeyword: true,
         notice: notice,
       );

  final List<KnowledgeItem> items;
  final bool usedSemanticSearch;
  final bool fellBackToKeyword;
  final String? notice;
}
