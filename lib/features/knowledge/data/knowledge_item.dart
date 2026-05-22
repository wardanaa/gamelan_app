import '../../../core/api/api_parsers.dart';
import '../../../core/mapping/taxonomy_mapper.dart';

class KnowledgeItem {
  const KnowledgeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.knowledgeType,
    required this.gamelanType,
    required this.relations,
    required this.sourceSummary,
    required this.provenanceSummary,
    this.slug,
    this.isCommunityApproved = false,
  });

  final String id;
  final String title;
  final String description;
  final String knowledgeType;
  final String gamelanType;
  final List<String> relations;
  final String sourceSummary;
  final String provenanceSummary;
  final String? slug;
  final bool isCommunityApproved;

  static KnowledgeItem? fromApi(
    Map<String, Object?> json, {
    TaxonomyMapper? taxonomy,
  }) {
    final mapper = taxonomy ?? TaxonomyMapper();
    final source = nestedObject(json, const ['knowledge_item']) ?? json;
    final id = stringFrom(source, const ['id', 'uuid']);
    final title = stringFrom(source, const ['title']);
    if (id == null || title == null) {
      return null;
    }

    final knowledgeSlug = stringFrom(source, const ['knowledge_type']);
    final gamelanSlug = stringFrom(source, const ['gamelan_type']);
    final relations = _relationsFromApi(source);

    return KnowledgeItem(
      id: id,
      slug: stringFrom(source, const ['slug']),
      title: title,
      description: stringFrom(source, const ['description']) ?? '',
      knowledgeType: stringFrom(source, const ['knowledge_type_label']) ??
          (knowledgeSlug == null
              ? 'Unknown'
              : mapper.knowledgeLabelFromSlug(knowledgeSlug)),
      gamelanType: stringFrom(source, const ['gamelan_type_label']) ??
          (gamelanSlug == null
              ? 'Unknown'
              : mapper.gamelanLabelFromSlug(gamelanSlug)),
      relations: relations,
      sourceSummary: stringFrom(source, const ['source_summary']) ?? '',
      provenanceSummary: stringFrom(source, const [
            'provenance_summary',
          ]) ??
          'Published knowledge from the backend API.',
      isCommunityApproved: true,
    );
  }

  static List<KnowledgeItem> listFromApi(
    Object? data, {
    TaxonomyMapper? taxonomy,
  }) {
    if (data is Iterable) {
      return data
          .map((entry) {
            final map = asObjectMap(entry);
            final nested = nestedObject(map, const ['knowledge_item']) ?? map;
            return fromApi(nested, taxonomy: taxonomy);
          })
          .whereType<KnowledgeItem>()
          .toList(growable: false);
    }

    final map = asObjectMap(data);
    final knowledgeItems = nestedObject(map, const ['knowledge_items']);
    if (knowledgeItems != null) {
      return listFromApi(knowledgeItems, taxonomy: taxonomy);
    }

    final results = map['results'];
    if (results != null) {
      return listFromApi(results, taxonomy: taxonomy);
    }

    final single = fromApi(map, taxonomy: taxonomy);
    if (single != null) {
      return [single];
    }
    return const [];
  }

  static List<String> _relationsFromApi(Map<String, Object?> source) {
    final relations = source['relations'];
    if (relations is! Iterable) {
      return const [];
    }

    final labels = <String>[];
    for (final relation in relations) {
      final map = asObjectMap(relation);
      final property = stringFrom(map, const ['property', 'relation']);
      final objectLabel = stringFrom(map, const [
        'object_label',
        'label',
        'related_label',
      ]);
      if (property != null && objectLabel != null) {
        labels.add('$property: $objectLabel');
      } else if (objectLabel != null) {
        labels.add(objectLabel);
      }
    }
    return labels;
  }
}
