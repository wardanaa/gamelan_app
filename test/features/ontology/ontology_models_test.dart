import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/features/ontology/data/ontology_class.dart';
import 'package:gamelan_app/features/ontology/data/ontology_entity.dart';
import 'package:gamelan_app/features/ontology/data/ontology_mapping.dart';
import 'package:gamelan_app/features/ontology/data/ontology_property.dart';
import 'package:gamelan_app/features/ontology/data/ontology_relation.dart';

void main() {
  test('ontology class parses and serializes snake_case data', () {
    final ontologyClass = OntologyClass.fromApi({
      'id': 'ontology-class-uuid',
      'uri': 'https://example.org/gamelan#Instrument',
      'label': 'Instrument',
      'description': 'Musical instrument used in gamelan.',
      'entity_type': 'Instrument',
    });

    expect(ontologyClass, isNotNull);
    expect(ontologyClass!.id, 'ontology-class-uuid');
    expect(ontologyClass.uri, startsWith('https://'));
    expect(ontologyClass.label, 'Instrument');
    expect(ontologyClass.toJson()['entity_type'], 'Instrument');
  });

  test('ontology property parses and serializes domain and range', () {
    final property = OntologyProperty.fromApi({
      'id': 'ontology-property-uuid',
      'uri': 'https://example.org/gamelan#usedInEnsemble',
      'label': 'usedInEnsemble',
      'description': 'Instrument is used in ensemble.',
      'domain': 'Instrument',
      'range': 'Ensemble',
    });

    expect(property, isNotNull);
    expect(property!.domain, 'Instrument');
    expect(property.range, 'Ensemble');
    expect(property.toJson()['range'], 'Ensemble');
  });

  test('ontology entity parses published flags and stable identifiers', () {
    final entity = OntologyEntity.fromApi({
      'id': 'ontology-entity-id',
      'uuid': 'ontology-entity-uuid',
      'uri': 'https://example.org/gamelan/entity/gangsa-in-gong-kebyar',
      'slug': 'gangsa-in-gong-kebyar',
      'label': 'Gangsa in Gong Kebyar',
      'entity_type': 'Instrument',
      'description': 'Validated public description.',
      'is_published': true,
      'cultural_sensitivity': false,
    });

    expect(entity, isNotNull);
    expect(entity!.uuid, 'ontology-entity-uuid');
    expect(entity.isPublished, isTrue);
    expect(entity.culturalSensitivity, isFalse);
    expect(entity.toJson()['slug'], 'gangsa-in-gong-kebyar');
  });

  test('ontology relation and mapping parse nested relation lists', () {
    final relation = OntologyRelation.fromApi({
      'property': 'usedInEnsemble',
      'object_slug': 'gong-kebyar',
      'object_label': 'Gong Kebyar',
      'object_class': 'Ensemble',
    });

    final mapping = OntologyMapping.fromApi({
      'id': 'ontology-mapping-uuid',
      'contribution_id': 'contribution-uuid',
      'knowledge_item_id': 'knowledge-item-uuid',
      'ontology_class': 'Instrument',
      'subject_slug': 'gangsa-in-gong-kebyar',
      'preferred_label': 'Gangsa in Gong Kebyar',
      'language': 'id',
      'relations': [relation?.toJson()],
      'status': 'pending',
      'created_at': '2026-05-22T10:00:00.000000Z',
    });

    expect(relation, isNotNull);
    expect(relation!.objectClass, 'Ensemble');
    expect(mapping, isNotNull);
    expect(mapping!.relations, hasLength(1));
    expect(mapping.relations.single.property, 'usedInEnsemble');
    expect(mapping.toJson()['ontology_class'], 'Instrument');
  });
}
