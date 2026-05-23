import '../../../core/api/api_parsers.dart';
import 'ontology_relation.dart';

class OntologyMapping {
  const OntologyMapping({
    required this.id,
    required this.contributionId,
    required this.knowledgeItemId,
    required this.ontologyClass,
    required this.subjectSlug,
    required this.preferredLabel,
    required this.language,
    required this.relations,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String contributionId;
  final String? knowledgeItemId;
  final String ontologyClass;
  final String subjectSlug;
  final String preferredLabel;
  final String language;
  final List<OntologyRelation> relations;
  final String status;
  final DateTime createdAt;

  static List<OntologyMapping> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(OntologyMapping.fromApi)
        .whereType<OntologyMapping>()
        .toList(growable: false);
  }

  static OntologyMapping? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static OntologyMapping? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final contributionId = stringFrom(json, const ['contribution_id']);
    final ontologyClass = stringFrom(json, const ['ontology_class']);
    final subjectSlug = stringFrom(json, const ['subject_slug']);
    final preferredLabel = stringFrom(json, const [
      'preferred_label',
      'label',
      'title',
    ]);
    final language = stringFrom(json, const ['language']) ?? 'id';
    final status = stringFrom(json, const ['status']);
    final createdAt = dateTimeFrom(json, const ['created_at']);
    if (id == null ||
        contributionId == null ||
        ontologyClass == null ||
        subjectSlug == null ||
        preferredLabel == null ||
        status == null ||
        createdAt == null) {
      return null;
    }

    return OntologyMapping(
      id: id,
      contributionId: contributionId,
      knowledgeItemId: stringFrom(json, const ['knowledge_item_id']),
      ontologyClass: ontologyClass,
      subjectSlug: subjectSlug,
      preferredLabel: preferredLabel,
      language: language,
      relations: OntologyRelation.listFromApi(
        json['relations'] ?? json['ontology_relations'],
      ),
      status: status,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'contribution_id': contributionId,
      'knowledge_item_id': knowledgeItemId,
      'ontology_class': ontologyClass,
      'subject_slug': subjectSlug,
      'preferred_label': preferredLabel,
      'language': language,
      'relations': relations.map((relation) => relation.toJson()).toList(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
