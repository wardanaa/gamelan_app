import '../../../core/api/api_client.dart';
import '../../../core/utils/result.dart';
import 'ontology_class.dart';
import 'ontology_entity.dart';
import 'ontology_entity_page.dart';
import 'ontology_property.dart';
import 'ontology_repository.dart';

class LocalOntologyRepository implements OntologyRepository {
  LocalOntologyRepository()
    : _classes = List<OntologyClass>.unmodifiable(_seedClasses),
      _properties = List<OntologyProperty>.unmodifiable(_seedProperties),
      _entities = List<OntologyEntity>.unmodifiable(_seedEntities);

  static final List<OntologyClass> _seedClasses = [
    OntologyClass(
      id: 'ontology-class-instrument',
      uri: 'https://example.org/gamelan#Instrument',
      label: 'Instrument',
      description: 'Musical instrument used in gamelan.',
      entityType: 'Instrument',
    ),
    OntologyClass(
      id: 'ontology-class-ensemble',
      uri: 'https://example.org/gamelan#Ensemble',
      label: 'Ensemble',
      description: 'Gamelan ensemble or group arrangement.',
      entityType: 'Ensemble',
    ),
    OntologyClass(
      id: 'ontology-class-person',
      uri: 'https://example.org/gamelan#Person',
      label: 'Person',
      description: 'Practitioner, composer, teacher, or maker.',
      entityType: 'Person',
    ),
    OntologyClass(
      id: 'ontology-class-place',
      uri: 'https://example.org/gamelan#Place',
      label: 'Place',
      description: 'Village, region, temple, venue, or cultural location.',
      entityType: 'Place',
    ),
  ];

  static final List<OntologyProperty> _seedProperties = [
    OntologyProperty(
      id: 'ontology-property-used-in-ensemble',
      uri: 'https://example.org/gamelan#usedInEnsemble',
      label: 'usedInEnsemble',
      description: 'Instrument is used in ensemble.',
      domain: 'Instrument',
      range: 'Ensemble',
    ),
    OntologyProperty(
      id: 'ontology-property-has-instrument',
      uri: 'https://example.org/gamelan#hasInstrument',
      label: 'hasInstrument',
      description: 'Ensemble has instrument.',
      domain: 'Ensemble',
      range: 'Instrument',
    ),
    OntologyProperty(
      id: 'ontology-property-performed-by',
      uri: 'https://example.org/gamelan#performedBy',
      label: 'performedBy',
      description: 'Performance or composition performed by person or group.',
      domain: 'Performance',
      range: 'Person',
    ),
  ];

  static final List<OntologyEntity> _seedEntities = [
    OntologyEntity(
      id: 'ontology-entity-gangsa',
      uuid: 'ontology-entity-gangsa-uuid',
      uri: 'https://example.org/gamelan/entity/gangsa',
      slug: 'gangsa',
      label: 'Gangsa',
      entityType: 'Instrument',
      description: 'A keyed metallophone commonly used in Balinese gamelan.',
      isPublished: true,
      culturalSensitivity: false,
    ),
    OntologyEntity(
      id: 'ontology-entity-gong-kebyar',
      uuid: 'ontology-entity-gong-kebyar-uuid',
      uri: 'https://example.org/gamelan/entity/gong-kebyar',
      slug: 'gong-kebyar',
      label: 'Gong Kebyar',
      entityType: 'Ensemble',
      description: 'A dynamic Balinese gamelan ensemble style.',
      isPublished: true,
      culturalSensitivity: false,
    ),
    OntologyEntity(
      id: 'ontology-entity-denpasar',
      uuid: 'ontology-entity-denpasar-uuid',
      uri: 'https://example.org/gamelan/entity/denpasar',
      slug: 'denpasar',
      label: 'Denpasar',
      entityType: 'Place',
      description: 'A Balinese city and cultural center.',
      isPublished: true,
      culturalSensitivity: false,
    ),
    OntologyEntity(
      id: 'ontology-entity-wayang',
      uuid: 'ontology-entity-wayang-uuid',
      uri: 'https://example.org/gamelan/entity/wayang',
      slug: 'wayang',
      label: 'Wayang',
      entityType: 'Term',
      description: 'A traditional performance or cultural term.',
      isPublished: false,
      culturalSensitivity: false,
    ),
  ];

  final List<OntologyClass> _classes;
  final List<OntologyProperty> _properties;
  final List<OntologyEntity> _entities;

  @override
  Future<Result<List<OntologyClass>>> getClasses() async {
    return Success(_classes);
  }

  @override
  Future<Result<List<OntologyProperty>>> getProperties() async {
    return Success(_properties);
  }

  @override
  Future<Result<OntologyEntityPage>> getEntities({
    String? type,
    int page = 1,
    int perPage = 10,
  }) async {
    final normalizedType = type?.trim().toLowerCase();
    final filtered = normalizedType == null || normalizedType.isEmpty
        ? _entities
        : _entities
              .where(
                (entity) => entity.entityType.toLowerCase() == normalizedType,
              )
              .toList(growable: false);
    final safePage = page < 1 ? 1 : page;
    final safePerPage = perPage < 1 ? 1 : perPage;
    final start = (safePage - 1) * safePerPage;
    final items = start >= filtered.length
        ? const <OntologyEntity>[]
        : filtered.skip(start).take(safePerPage).toList(growable: false);

    return Success(
      OntologyEntityPage(
        entities: items,
        paginationMeta: ApiPaginationMeta(
          currentPage: safePage,
          perPage: safePerPage,
          total: filtered.length,
        ),
      ),
    );
  }

  @override
  Future<Result<OntologyEntity?>> getEntity(String id) async {
    final normalizedId = id.trim();
    for (final entity in _entities) {
      if (entity.id == normalizedId || entity.uuid == normalizedId) {
        return Success(entity);
      }
    }
    return const Success(null);
  }
}
