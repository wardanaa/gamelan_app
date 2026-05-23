import '../../../core/api/api_parsers.dart';

class OntologyEntity {
  const OntologyEntity({
    required this.id,
    required this.uuid,
    required this.uri,
    required this.slug,
    required this.label,
    required this.entityType,
    required this.description,
    required this.isPublished,
    required this.culturalSensitivity,
  });

  final String id;
  final String uuid;
  final String uri;
  final String slug;
  final String label;
  final String entityType;
  final String description;
  final bool isPublished;
  final bool culturalSensitivity;

  static List<OntologyEntity> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(OntologyEntity.fromApi)
        .whereType<OntologyEntity>()
        .toList(growable: false);
  }

  static OntologyEntity? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static OntologyEntity? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final uuid = stringFrom(json, const ['uuid', 'id']);
    final uri = stringFrom(json, const ['uri']);
    final slug = stringFrom(json, const ['slug']);
    final label = stringFrom(json, const ['label', 'name', 'title']);
    final entityType = stringFrom(json, const ['entity_type', 'entityType']);
    final description = stringFrom(json, const ['description']);
    if (id == null ||
        uuid == null ||
        uri == null ||
        slug == null ||
        label == null ||
        entityType == null ||
        description == null) {
      return null;
    }

    return OntologyEntity(
      id: id,
      uuid: uuid,
      uri: uri,
      slug: slug,
      label: label,
      entityType: entityType,
      description: description,
      isPublished: boolFrom(json, const ['is_published', 'isPublished']),
      culturalSensitivity: boolFrom(json, const [
        'cultural_sensitivity',
        'culturalSensitivity',
      ]),
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'uri': uri,
      'slug': slug,
      'label': label,
      'entity_type': entityType,
      'description': description,
      'is_published': isPublished,
      'cultural_sensitivity': culturalSensitivity,
    };
  }
}
