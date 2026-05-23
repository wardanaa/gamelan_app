import '../../../core/api/api_parsers.dart';

class OntologyRelation {
  const OntologyRelation({
    required this.property,
    required this.objectSlug,
    required this.objectLabel,
    required this.objectClass,
  });

  final String property;
  final String objectSlug;
  final String objectLabel;
  final String objectClass;

  static List<OntologyRelation> listFromApi(Object? value) {
    return asObjectMapList(value)
        .map(OntologyRelation.fromApi)
        .whereType<OntologyRelation>()
        .toList(growable: false);
  }

  static OntologyRelation? fromApi(Object? value) {
    return fromJson(asObjectMap(value));
  }

  static OntologyRelation? fromJson(Map<String, Object?> json) {
    final property = stringFrom(json, const ['property', 'relation']);
    final objectSlug = stringFrom(json, const ['object_slug', 'objectSlug']);
    final objectLabel = stringFrom(json, const ['object_label', 'objectLabel']);
    final objectClass = stringFrom(json, const ['object_class', 'objectClass']);
    if (property == null ||
        objectSlug == null ||
        objectLabel == null ||
        objectClass == null) {
      return null;
    }

    return OntologyRelation(
      property: property,
      objectSlug: objectSlug,
      objectLabel: objectLabel,
      objectClass: objectClass,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'property': property,
      'object_slug': objectSlug,
      'object_label': objectLabel,
      'object_class': objectClass,
    };
  }
}
