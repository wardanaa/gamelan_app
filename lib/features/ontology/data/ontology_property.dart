import '../../../core/api/api_parsers.dart';

class OntologyProperty {
  const OntologyProperty({
    required this.id,
    required this.uri,
    required this.label,
    required this.description,
    required this.domain,
    required this.range,
  });

  final String id;
  final String uri;
  final String label;
  final String description;
  final String domain;
  final String range;

  static List<OntologyProperty> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(OntologyProperty.fromApi)
        .whereType<OntologyProperty>()
        .toList(growable: false);
  }

  static OntologyProperty? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static OntologyProperty? fromJson(Map<String, Object?> json) {
    final id = stringFrom(json, const ['id', 'uuid']);
    final uri = stringFrom(json, const ['uri']);
    final label = stringFrom(json, const ['label', 'name', 'title']);
    final description = stringFrom(json, const ['description']);
    final domain = stringFrom(json, const ['domain']);
    final range = stringFrom(json, const ['range']);
    if (id == null ||
        uri == null ||
        label == null ||
        description == null ||
        domain == null ||
        range == null) {
      return null;
    }

    return OntologyProperty(
      id: id,
      uri: uri,
      label: label,
      description: description,
      domain: domain,
      range: range,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'uri': uri,
      'label': label,
      'description': description,
      'domain': domain,
      'range': range,
    };
  }
}
