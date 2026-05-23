import '../../../core/api/api_parsers.dart';

enum RdfPublicationStatus {
  pending,
  published,
  failed,
  deprecated;

  String get apiValue => name;

  String get label => switch (this) {
    RdfPublicationStatus.pending => 'Pending',
    RdfPublicationStatus.published => 'Published',
    RdfPublicationStatus.failed => 'Failed',
    RdfPublicationStatus.deprecated => 'Deprecated',
  };

  static RdfPublicationStatus fromApiValue(String value) {
    final normalized = value.trim().toLowerCase();
    return switch (normalized) {
      'published' => RdfPublicationStatus.published,
      'failed' => RdfPublicationStatus.failed,
      'deprecated' => RdfPublicationStatus.deprecated,
      _ => RdfPublicationStatus.pending,
    };
  }
}

class RdfPublicationPublisher {
  const RdfPublicationPublisher({required this.id, required this.name});

  final String id;
  final String name;

  static RdfPublicationPublisher? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static RdfPublicationPublisher? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final name = stringFrom(json, const ['name', 'display_name']);
    if (id == null || name == null) {
      return null;
    }

    return RdfPublicationPublisher(id: id, name: name);
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'name': name};
  }
}

class RdfPublicationModel {
  const RdfPublicationModel({
    required this.id,
    required this.contributionId,
    required this.ontologyMappingId,
    required this.rdfSubjectUri,
    required this.rdfGraphUri,
    required this.status,
    required this.publishedBy,
    required this.metadata,
    required this.createdAt,
    this.knowledgeItemId,
    this.publishedAt,
    this.errorMessage,
  });

  final String id;
  final String contributionId;
  final String? knowledgeItemId;
  final String ontologyMappingId;
  final String rdfSubjectUri;
  final String rdfGraphUri;
  final RdfPublicationStatus status;
  final DateTime? publishedAt;
  final RdfPublicationPublisher publishedBy;
  final String? errorMessage;
  final Map<String, Object?> metadata;
  final DateTime createdAt;

  static RdfPublicationModel? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static RdfPublicationModel? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final contributionId = stringFrom(json, const ['contribution_id']);
    final ontologyMappingId = stringFrom(json, const ['ontology_mapping_id']);
    final rdfSubjectUri = stringFrom(json, const ['rdf_subject_uri']);
    final rdfGraphUri = stringFrom(json, const ['rdf_graph_uri']);
    final status = stringFrom(json, const ['status']);
    final publishedBy = RdfPublicationPublisher.fromApi(
      json['published_by'] ?? json['publishedBy'],
    );
    final createdAt = dateTimeFrom(json, const ['created_at']);
    if (id == null ||
        contributionId == null ||
        ontologyMappingId == null ||
        rdfSubjectUri == null ||
        rdfGraphUri == null ||
        status == null ||
        publishedBy == null ||
        createdAt == null) {
      return null;
    }

    return RdfPublicationModel(
      id: id,
      contributionId: contributionId,
      knowledgeItemId: stringFrom(json, const ['knowledge_item_id']),
      ontologyMappingId: ontologyMappingId,
      rdfSubjectUri: rdfSubjectUri,
      rdfGraphUri: rdfGraphUri,
      status: RdfPublicationStatus.fromApiValue(status),
      publishedAt: dateTimeFrom(json, const ['published_at']),
      publishedBy: publishedBy,
      errorMessage: stringFrom(json, const ['error_message']),
      metadata: asObjectMap(json['metadata']),
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'contribution_id': contributionId,
      'knowledge_item_id': knowledgeItemId,
      'ontology_mapping_id': ontologyMappingId,
      'rdf_subject_uri': rdfSubjectUri,
      'rdf_graph_uri': rdfGraphUri,
      'status': status.apiValue,
      'published_at': publishedAt?.toIso8601String(),
      'published_by': publishedBy.toJson(),
      'error_message': errorMessage,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
