import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/ontology/data/local_ontology_repository.dart';
import 'package:gamelan_app/features/ontology/data/ontology_class.dart';
import 'package:gamelan_app/features/ontology/data/ontology_entity.dart';
import 'package:gamelan_app/features/ontology/data/ontology_entity_page.dart';
import 'package:gamelan_app/features/ontology/data/ontology_property.dart';
import 'package:gamelan_app/features/ontology/data/remote_ontology_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'local ontology repository returns stable fixtures and paging',
    () async {
      final repository = LocalOntologyRepository();

      final classesResult = await repository.getClasses();
      final classes = switch (classesResult) {
        Success<List<OntologyClass>>(:final value) => value,
        Failure<List<OntologyClass>>() => fail('Expected success'),
      };
      expect(classes, isNotEmpty);
      expect(classes.map((item) => item.label), contains('Instrument'));

      final propertiesResult = await repository.getProperties();
      final properties = switch (propertiesResult) {
        Success<List<OntologyProperty>>(:final value) => value,
        Failure<List<OntologyProperty>>() => fail('Expected success'),
      };
      expect(properties, isNotEmpty);
      expect(properties.map((item) => item.label), contains('usedInEnsemble'));

      final pageResult = await repository.getEntities(
        type: 'Instrument',
        perPage: 1,
      );
      final page = switch (pageResult) {
        Success<OntologyEntityPage>(:final value) => value,
        Failure<OntologyEntityPage>() => fail('Expected success'),
      };
      expect(page.entities, hasLength(1));
      expect(page.paginationMeta.currentPage, 1);
      expect(page.paginationMeta.perPage, 1);
      expect(page.paginationMeta.total, greaterThanOrEqualTo(1));

      final entityResult = await repository.getEntity('ontology-entity-gangsa');
      final entity = switch (entityResult) {
        Success<OntologyEntity?>(:final value) => value,
        Failure<OntologyEntity?>() => fail('Expected success'),
      };
      expect(entity?.label, 'Gangsa');
    },
  );

  test(
    'remote ontology repository parses collections, pagination, and 404s',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/ontology/classes')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'ontology-class-uuid',
                'uri': 'https://example.org/gamelan#Instrument',
                'label': 'Instrument',
                'description': 'Musical instrument used in gamelan.',
                'entity_type': 'Instrument',
              },
            ],
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/ontology/properties')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'ontology-property-uuid',
                'uri': 'https://example.org/gamelan#usedInEnsemble',
                'label': 'usedInEnsemble',
                'description': 'Instrument is used in ensemble.',
                'domain': 'Instrument',
                'range': 'Ensemble',
              },
            ],
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/ontology/entities')) {
          expect(request.url.queryParameters['type'], 'Instrument');
          expect(request.url.queryParameters['page'], '2');
          expect(request.url.queryParameters['per_page'], '1');
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'entities': [
                {
                  'id': 'ontology-entity-uuid',
                  'uuid': 'ontology-entity-uuid',
                  'uri': 'https://example.org/gamelan/entity/gangsa',
                  'slug': 'gangsa',
                  'label': 'Gangsa',
                  'entity_type': 'Instrument',
                  'description': 'Validated public description.',
                  'is_published': true,
                  'cultural_sensitivity': false,
                },
              ],
            },
            'meta': {'current_page': 2, 'per_page': 1, 'total': 3},
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith(
              '/ontology/entities/ontology-entity-uuid',
            )) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'entity': {
                'id': 'ontology-entity-uuid',
                'uuid': 'ontology-entity-uuid',
                'uri': 'https://example.org/gamelan/entity/gangsa',
                'slug': 'gangsa',
                'label': 'Gangsa',
                'entity_type': 'Instrument',
                'description': 'Validated public description.',
                'is_published': true,
                'cultural_sensitivity': false,
              },
            },
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/ontology/entities/missing-entity')) {
          return jsonResponse({
            'success': false,
            'message': 'Not found',
            'errors': {},
          }, 404);
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteOntologyRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final classesResult = await repository.getClasses();
      final classes = switch (classesResult) {
        Success<List<OntologyClass>>(:final value) => value,
        Failure<List<OntologyClass>>() => fail('Expected success'),
      };
      expect(classes.single.label, 'Instrument');

      final propertiesResult = await repository.getProperties();
      final properties = switch (propertiesResult) {
        Success<List<OntologyProperty>>(:final value) => value,
        Failure<List<OntologyProperty>>() => fail('Expected success'),
      };
      expect(properties.single.range, 'Ensemble');

      final pageResult = await repository.getEntities(
        type: 'Instrument',
        page: 2,
        perPage: 1,
      );
      final page = switch (pageResult) {
        Success<OntologyEntityPage>(:final value) => value,
        Failure<OntologyEntityPage>() => fail('Expected success'),
      };
      expect(page.entities.single.slug, 'gangsa');
      expect(page.paginationMeta.currentPage, 2);
      expect(page.paginationMeta.perPage, 1);
      expect(page.paginationMeta.total, 3);

      final entityResult = await repository.getEntity('ontology-entity-uuid');
      final entity = switch (entityResult) {
        Success<OntologyEntity?>(:final value) => value,
        Failure<OntologyEntity?>() => fail('Expected success'),
      };
      expect(entity?.isPublished, isTrue);

      final missingResult = await repository.getEntity('missing-entity');
      final missing = switch (missingResult) {
        Success<OntologyEntity?>(:final value) => value,
        Failure<OntologyEntity?>() => fail('Expected success'),
      };
      expect(missing, isNull);
    },
  );

  test(
    'remote ontology repository fails on empty entity collections',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/ontology/entities')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {'entities': []},
            'meta': {'current_page': 1, 'per_page': 10, 'total': 0},
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteOntologyRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final result = await repository.getEntities();
      expect(result, isA<Failure<OntologyEntityPage>>());
    },
  );
}

http.Response jsonResponse(Object body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: const {'content-type': 'application/json'},
  );
}
