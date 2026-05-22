import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import 'knowledge_item.dart';

abstract class KnowledgeRepository {
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems();

  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id);

  Future<Result<List<KnowledgeItem>>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  });

  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes();

  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes();
}
