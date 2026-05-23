import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/contributions/data/rdf_publication_model.dart';
import 'package:gamelan_app/features/ontology/data/ontology_mapping.dart';
import 'package:gamelan_app/features/ontology/data/ontology_relation.dart';
import 'package:gamelan_app/features/contributions/data/remote_contribution_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'remote contribution repository queues rdf publication and reads it back',
    () async {
      var queued = false;
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/contributions/contribution-uuid') &&
            queued) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'contribution': {
                'id': 'contribution-uuid',
                'title': 'Gangsa in Gong Kebyar',
                'description': 'Validated public description.',
                'status': 'curator_approved',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Community interview and local practice note.',
                'contributor_note': 'Submitted as community knowledge.',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
                'rdf_publication': {
                  'id': 'rdf-publication-uuid',
                  'contribution_id': 'contribution-uuid',
                  'ontology_mapping_id': 'mapping-uuid',
                  'rdf_subject_uri':
                      'https://example.org/gamelan/entity/gangsa-in-gong-kebyar',
                  'rdf_graph_uri': 'graph/published',
                  'status': 'pending',
                  'published_at': null,
                  'published_by': {'id': 2, 'name': 'Made Curator'},
                  'error_message': null,
                  'metadata': {
                    'ontology_class': 'Instrument',
                    'subject_slug': 'gangsa-in-gong-kebyar',
                    'relations_count': 1,
                  },
                  'created_at': '2026-05-22T11:00:00.000000Z',
                },
              },
            },
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/contributions/contribution-uuid')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'contribution': {
                'id': 'contribution-uuid',
                'title': 'Gangsa in Gong Kebyar',
                'description': 'Validated public description.',
                'status': 'curator_approved',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Community interview and local practice note.',
                'contributor_note': 'Submitted as community knowledge.',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
              },
            },
          });
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith(
              '/contributions/contribution-uuid/rdf-publications',
            )) {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['ontology_class'], 'Instrument');
          expect(body['subject_slug'], 'gangsa-in-gong-kebyar');
          expect(body['preferred_label'], 'Gangsa in Gong Kebyar');
          expect(body['language'], 'id');
          expect(
            body['source_summary'],
            'Community interview and local practice note.',
          );
          final relations = body['relations'] as List<Object?>;
          expect(relations, hasLength(1));
          final relation = relations.single as Map<String, Object?>;
          expect(relation['property'], 'usedInEnsemble');
          expect(relation['object_slug'], 'gong-kebyar');
          queued = true;
          return jsonResponse({
            'success': true,
            'message': 'RDF publication queued successfully.',
            'data': {
              'rdf_publication': {
                'id': 'rdf-publication-uuid',
                'contribution_id': 'contribution-uuid',
                'knowledge_item_id': null,
                'ontology_mapping_id': 'mapping-uuid',
                'rdf_subject_uri':
                    'https://example.org/gamelan/entity/gangsa-in-gong-kebyar',
                'rdf_graph_uri': 'graph/published',
                'status': 'pending',
                'published_at': null,
                'published_by': {'id': 2, 'name': 'Made Curator'},
                'error_message': null,
                'metadata': {
                  'ontology_class': 'Instrument',
                  'subject_slug': 'gangsa-in-gong-kebyar',
                  'relations_count': 1,
                  'provenance_graph_uri': 'graph/provenance',
                },
                'created_at': '2026-05-22T11:00:00.000000Z',
              },
            },
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteContributionRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final mapping = OntologyMapping(
        id: 'mapping-uuid',
        contributionId: 'contribution-uuid',
        knowledgeItemId: null,
        ontologyClass: 'Instrument',
        subjectSlug: 'gangsa-in-gong-kebyar',
        preferredLabel: 'Gangsa in Gong Kebyar',
        language: 'id',
        relations: const [
          OntologyRelation(
            property: 'usedInEnsemble',
            objectSlug: 'gong-kebyar',
            objectLabel: 'Gong Kebyar',
            objectClass: 'Ensemble',
          ),
        ],
        status: 'pending',
        createdAt: DateTime(2026, 5, 22, 10),
      );

      final queueResult = await repository.queueRdfPublication(
        'contribution-uuid',
        mapping,
      );
      final publication = switch (queueResult) {
        Success<RdfPublicationModel>(:final value) => value,
        Failure<RdfPublicationModel>(:final message) => fail(message),
      };
      expect(publication.status, RdfPublicationStatus.pending);
      expect(publication.publishedBy.name, 'Made Curator');

      final readBackResult = await repository.getRdfPublication(
        'contribution-uuid',
      );
      final readBack = switch (readBackResult) {
        Success<RdfPublicationModel?>(:final value) => value,
        Failure<RdfPublicationModel?>() => fail('Expected success'),
      };
      expect(readBack?.id, 'rdf-publication-uuid');
      expect(readBack?.metadata['relations_count'], 1);
    },
  );

  test(
    'remote contribution repository returns null rdf publication when absent',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/contributions/contribution-uuid')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'contribution': {
                'id': 'contribution-uuid',
                'title': 'Gangsa note',
                'description': 'Validated public description.',
                'status': 'curator_approved',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Community interview and local practice note.',
                'contributor_note': 'Submitted as community knowledge.',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
              },
            },
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteContributionRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final result = await repository.getRdfPublication('contribution-uuid');
      final publication = switch (result) {
        Success<RdfPublicationModel?>(:final value) => value,
        Failure<RdfPublicationModel?>() => fail('Expected success'),
      };
      expect(publication, isNull);
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
