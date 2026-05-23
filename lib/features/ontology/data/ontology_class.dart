import '../../../core/api/api_parsers.dart';

class OntologyClass {
  const OntologyClass({
    required this.id,
    required this.uri,
    required this.label,
    required this.description,
    required this.entityType,
  });

  final String id;
  final String uri;
  final String label;
  final String description;
  final String entityType;

  static List<OntologyClass> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(OntologyClass.fromApi)
        .whereType<OntologyClass>()
        .toList(growable: false);
  }

  static OntologyClass? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static OntologyClass? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final uri = stringFrom(json, const ['uri']);
    final label = stringFrom(json, const ['label', 'name', 'title']);
    final description = stringFrom(json, const ['description']);
    final entityType = stringFrom(json, const ['entity_type', 'entityType']);
    if (id == null ||
        uri == null ||
        label == null ||
        description == null ||
        entityType == null) {
      return null;
    }

    return OntologyClass(
      id: id,
      uri: uri,
      label: label,
      description: description,
      entityType: entityType,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'uri': uri,
      'label': label,
      'description': description,
      'entity_type': entityType,
    };
  }
}
