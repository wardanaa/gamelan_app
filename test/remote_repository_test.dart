import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/contributions/data/remote_contribution_repository.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_repository.dart';
import 'package:gamelan_app/features/knowledge/data/remote_knowledge_repository.dart';
import 'package:gamelan_app/features/provenance/data/provenance_timeline_entry.dart';
import 'package:gamelan_app/features/review/data/remote_review_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'remote contribution repository parses list and create responses',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/contributions')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'contribution-uuid',
                'title': 'Gangsa note',
                'description': 'Practice note',
                'status': 'draft',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Interview',
                'contributor_note': 'Community note',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
                'updated_at': '2026-05-22T10:00:00.000000Z',
                'allowed_actions': ['view', 'edit', 'submit', 'archive'],
                'media_assets': [
                  {
                    'id': 'media-uuid',
                    'title': 'Gangsa instrument photo',
                    'media_type': 'image',
                    'mime_type': 'image/jpeg',
                    'file_size': 12345,
                    'consent_status': 'granted',
                    'visibility': 'private',
                    'cultural_sensitivity': false,
                    'credit': 'Community documentation',
                    'alt_text': 'Gangsa instrument photo.',
                  },
                ],
              },
            ],
          });
        }
        if (request.method == 'POST' &&
            request.url.path.endsWith('/contributions')) {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          expect(body['knowledge_type'], 'instrument');
          expect(body['gamelan_type'], 'gong_kebyar');
          return jsonResponse({
            'success': true,
            'message': 'Created',
            'data': {
              'contribution': {
                'id': 'new-uuid',
                'title': body['title'],
                'description': body['description'],
                'status': 'draft',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Interview',
                'contributor_note': 'Community note',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
                'updated_at': '2026-05-22T10:00:00.000000Z',
                'allowed_actions': ['view', 'edit', 'submit'],
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

      final listResult = await repository.fetchContributions();
      final contributions = switch (listResult) {
        Success<List<ContributionModel>>(:final value) => value,
        Failure<List<ContributionModel>>() => fail('Expected success'),
      };
      expect(contributions, hasLength(1));
      expect(contributions.single.knowledgeType, 'Instrument');
      expect(contributions.single.canSubmit, isTrue);
      expect(contributions.single.mediaAssets, hasLength(1));
      expect(
        contributions.single.mediaAssets.single.title,
        'Gangsa instrument photo',
      );

      final createResult = await repository.createContribution(
        const ContributionInput(
          title: 'Gangsa draft',
          description: '',
          knowledgeType: 'Instrument',
          gamelanType: 'Gong Kebyar',
          sourceNote: '',
          contributorNote: 'Community note',
          culturalSensitivity: false,
          consentGiven: true,
          submitForReview: false,
        ),
      );
      expect(createResult, isA<Success<ContributionModel>>());
    },
  );

  test('remote contribution repository uploads and removes media', () async {
    var uploadCalled = false;
    var deleteCalled = false;
    final client = MockClient((request) async {
      if (request.method == 'POST' &&
          request.url.path.endsWith('/contributions/contribution-uuid/media')) {
        uploadCalled = true;
        expect(headerValue(request, 'authorization'), 'Bearer test-token');
        expect(headerValue(request, 'idempotency-key'), isNotEmpty);
        expect(
          headerValue(request, 'content-type'),
          contains('multipart/form-data'),
        );
        expect(request.body, contains('name="title"'));
        expect(request.body, contains('Gangsa photo'));
        expect(request.body, contains('name="media_type"'));
        expect(request.body, contains('image'));
        expect(request.body, contains('name="consent_status"'));
        expect(request.body, contains('granted'));
        expect(request.body, contains('name="visibility"'));
        expect(request.body, contains('private'));
        expect(request.body, contains('name="file"; filename="gangsa.jpg"'));
        return jsonResponse({
          'success': true,
          'message': 'Uploaded',
          'data': {
            'media_asset': {
              'id': 'media-uuid',
              'title': 'Gangsa photo',
              'media_type': 'image',
              'mime_type': 'image/jpeg',
              'file_size': 4,
              'consent_status': 'granted',
              'visibility': 'private',
              'cultural_sensitivity': false,
              'created_at': '2026-05-22T10:00:00.000000Z',
            },
          },
        });
      }
      if (request.method == 'DELETE' &&
          request.url.path.endsWith(
            '/contributions/contribution-uuid/media/media-uuid',
          )) {
        deleteCalled = true;
        expect(headerValue(request, 'authorization'), 'Bearer test-token');
        expect(headerValue(request, 'idempotency-key'), isNotEmpty);
        return jsonResponse({'success': true, 'message': 'Removed'});
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

    final uploadResult = await repository.uploadMedia(
      'contribution-uuid',
      MediaUploadInput(
        title: 'Gangsa photo',
        mediaType: MediaType.image,
        consentStatus: MediaConsentStatus.granted,
        visibility: MediaVisibility.private,
        culturalSensitivity: false,
        filename: 'gangsa.jpg',
        bytes: Uint8List.fromList([1, 2, 3, 4]),
      ),
    );
    final uploaded = switch (uploadResult) {
      Success<MediaAssetModel>(:final value) => value,
      Failure<MediaAssetModel>(:final message) => fail(message),
    };
    expect(uploaded.id, 'media-uuid');
    expect(uploaded.visibility, MediaVisibility.private);

    final deleteResult = await repository.removeMedia(
      'contribution-uuid',
      'media-uuid',
    );
    expect(deleteResult, isA<Success<void>>());
    expect(uploadCalled, isTrue);
    expect(deleteCalled, isTrue);
  });

  test(
    'remote contribution repository parses safe version and provenance traces',
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
                'description': 'Practice note',
                'status': 'submitted',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Interview',
                'contributor_note': 'Community note',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
              },
            },
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith(
              '/contributions/contribution-uuid/versions',
            )) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'version_number': 2,
                'status': 'submitted',
                'change_note': 'Submitted for review.',
                'editor': {'id': 1, 'name': 'Made Contributor'},
                'snapshot': {'title': 'Gangsa note', 'status': 'submitted'},
                'edited_at': '2026-05-22T10:00:00.000000Z',
              },
            ],
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith(
              '/contributions/contribution-uuid/provenance',
            )) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'provenance-uuid',
                'event_type': 'contribution_submitted',
                'summary': 'Contribution submitted for review.',
                'actor': null,
                'source': {'type': 'Contribution'},
                'contribution_version_number': 2,
                'metadata': {
                  'status': 'submitted',
                  'private_note': 'Hidden note',
                  'ip_address': '127.0.0.1',
                  'user_agent': 'test-agent',
                },
                'occurred_at': '2026-05-22T10:00:00.000000Z',
              },
            ],
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

      final contributionResult = await repository.findContribution(
        'contribution-uuid',
      );
      final contribution = switch (contributionResult) {
        Success<ContributionModel?>(:final value) => value,
        Failure<ContributionModel?>() => fail('Expected success'),
      };
      expect(contribution?.triageSuggestion, isNull);

      final versionsResult = await repository.fetchContributionVersions(
        'contribution-uuid',
      );
      final versions = switch (versionsResult) {
        Success<List<ProvenanceTimelineEntry>>(:final value) => value,
        Failure<List<ProvenanceTimelineEntry>>() => fail('Expected success'),
      };
      expect(versions, hasLength(1));
      expect(versions.single.title, 'Version 2');
      expect(versions.single.safeActorLabel, 'Made Contributor');

      final provenanceResult = await repository.fetchContributionProvenance(
        'contribution-uuid',
      );
      final provenance = switch (provenanceResult) {
        Success<List<ProvenanceTimelineEntry>>(:final value) => value,
        Failure<List<ProvenanceTimelineEntry>>() => fail('Expected success'),
      };
      expect(provenance, hasLength(1));
      expect(
        provenance.single.safeActorLabel,
        'Actor withheld by backend policy',
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        contains('Status'),
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        isNot(contains('Private note')),
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        isNot(contains('Ip Address')),
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        isNot(contains('User Agent')),
      );
    },
  );

  test(
    'remote contribution repository tolerates malformed provenance payloads',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith(
              '/contributions/contribution-uuid/versions',
            )) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {'unexpected': 'shape'},
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith(
              '/contributions/contribution-uuid/provenance',
            )) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {'unexpected': 'shape'},
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

      final versionsResult = await repository.fetchContributionVersions(
        'contribution-uuid',
      );
      final versions = switch (versionsResult) {
        Success<List<ProvenanceTimelineEntry>>(:final value) => value,
        Failure<List<ProvenanceTimelineEntry>>() => fail('Expected success'),
      };
      expect(versions, isEmpty);

      final provenanceResult = await repository.fetchContributionProvenance(
        'contribution-uuid',
      );
      final provenance = switch (provenanceResult) {
        Success<List<ProvenanceTimelineEntry>>(:final value) => value,
        Failure<List<ProvenanceTimelineEntry>>() => fail('Expected success'),
      };
      expect(provenance, isEmpty);
    },
  );

  test('remote contribution repository maps validation failures', () async {
    final client = MockClient((request) async {
      return jsonResponse({
        'success': false,
        'message': 'Validation failed.',
        'errors': {
          'title': ['The title field is required.'],
        },
      }, 422);
    });

    final repository = RemoteContributionRepository(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: client,
      ),
      tokenResolver: () async => 'test-token',
    );

    final result = await repository.createContribution(
      const ContributionInput(
        title: '',
        description: '',
        knowledgeType: 'Instrument',
        gamelanType: 'Gong Kebyar',
        sourceNote: '',
        contributorNote: '',
        culturalSensitivity: false,
        consentGiven: true,
        submitForReview: false,
      ),
    );

    expect(result, isA<Failure<ContributionModel>>());
    final failure = result as Failure<ContributionModel>;
    expect(failure.message, 'Validation failed.');
  });

  test('remote review repository posts approve decisions', () async {
    var approveCalled = false;
    var markExpertRequiredCalled = false;
    var expertValidateCalled = false;
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path.endsWith('/reviews/queue')) {
        return jsonResponse({
          'success': true,
          'message': 'OK',
          'data': [
            {
              'id': 'queue-item',
              'title': 'Submitted item',
              'description': 'Description',
              'status': 'submitted',
              'knowledge_type': 'instrument',
              'knowledge_type_label': 'Instrument',
              'gamelan_type': 'gong_kebyar',
              'gamelan_type_label': 'Gong Kebyar',
              'source_note': 'Source',
              'contributor_note': 'Note',
              'cultural_sensitivity': false,
              'consent_status': 'granted',
              'created_at': '2026-05-22T10:00:00.000000Z',
              'updated_at': '2026-05-22T10:00:00.000000Z',
              'allowed_actions': ['approve', 'reject'],
              'private_note':
                  'Should not be exposed to contributor-facing clients.',
              'reviewer': {'id': 'reviewer-uuid', 'name': 'Curator Reviewer'},
              'expert': {'id': 'expert-uuid', 'name': 'Expert Validator'},
            },
          ],
        });
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/reviews/queue-item/approve')) {
        approveCalled = true;
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['note'], 'Approved for publication workflow.');
        return jsonResponse({
          'success': true,
          'message': 'Approved',
          'data': {},
        });
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith(
            '/reviews/queue-item/mark-expert-required',
          )) {
        markExpertRequiredCalled = true;
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['note'], 'Needs expert validation.');
        expect(body['expert_required_reasons'], [
          'origin_claim',
          'curator_flagged',
        ]);
        return jsonResponse({
          'success': true,
          'message': 'Marked for expert validation',
          'data': {},
        });
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/reviews/queue-item/expert-validate')) {
        expertValidateCalled = true;
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['decision'], 'approve');
        expect(body['note'], 'Expert validated.');
        expect(body['private_note'], 'Private review context.');
        return jsonResponse({
          'success': true,
          'message': 'Validated',
          'data': {},
        });
      }
      return jsonResponse({'success': false, 'message': 'Not found'}, 404);
    });

    final repository = RemoteReviewRepository(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: client,
      ),
      tokenResolver: () async => 'test-token',
    );

    final queueResult = await repository.fetchReviewQueue();
    final queue = switch (queueResult) {
      Success<List<ContributionModel>>(:final value) => value,
      Failure<List<ContributionModel>>() => fail('Expected success'),
    };
    expect(queue, hasLength(1));
    expect(queue.single.toJson().containsKey('private_note'), isFalse);
    expect(queue.single.toJson().containsKey('reviewer'), isFalse);
    expect(queue.single.toJson().containsKey('expert'), isFalse);

    final approveResult = await repository.approveContribution(
      'queue-item',
      'Approved for publication workflow.',
    );
    expect(approveResult, isA<Success<void>>());
    expect(approveCalled, isTrue);

    final markExpertRequiredResult = await repository.markExpertRequired(
      'queue-item',
      'Needs expert validation.',
      ['origin_claim', 'curator_flagged'],
    );
    expect(markExpertRequiredResult, isA<Success<void>>());
    expect(markExpertRequiredCalled, isTrue);

    final expertValidateResult = await repository.expertValidate(
      'queue-item',
      'approve',
      'Expert validated.',
      'Private review context.',
    );
    expect(expertValidateResult, isA<Success<void>>());
    expect(expertValidateCalled, isTrue);
  });

  test(
    'remote review repository parses triage suggestions and review provenance',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/reviews/queue')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'queue-item',
                'title': 'Submitted item',
                'description': 'Description',
                'status': 'submitted',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_note': 'Source',
                'contributor_note': 'Note',
                'cultural_sensitivity': false,
                'consent_status': 'granted',
                'created_at': '2026-05-22T10:00:00.000000Z',
                'updated_at': '2026-05-22T10:00:00.000000Z',
                'allowed_actions': ['approve', 'reject'],
                'triage_suggestion': {
                  'label': 'AI suggestion, not validated.',
                  'provider': 'rules',
                  'status': 'suggested',
                  'model_name': 'rule-based-v1',
                  'processed_at': '2026-05-22T10:00:00.000000Z',
                  'confidence_score': '0.7600',
                  'suggested_entity_type': 'instrument',
                  'suggested_relations': [],
                  'duplicate_candidates': [],
                  'missing_metadata': [],
                  'language_normalization': {'suggested_language': 'id'},
                  'curator_summary': 'Extractive summary from submitted text.',
                  'uncertainty_notes': ['Human validation is still required.'],
                },
              },
            ],
          });
        }
        if (request.method == 'GET' &&
            request.url.path.endsWith('/reviews/queue-item/provenance')) {
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'id': 'review-provenance-uuid',
                'event_type': 'review_recorded',
                'summary': 'Review recorded.',
                'actor': {'id': 1, 'name': 'Curator Reviewer'},
                'source': {'type': 'Review'},
                'contribution_version_number': 2,
                'metadata': {
                  'status': 'under_review',
                  'private_note': 'Hidden review note',
                  'raw_response': 'Hidden AI response',
                },
                'occurred_at': '2026-05-22T10:00:00.000000Z',
              },
            ],
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteReviewRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final queueResult = await repository.fetchReviewQueue();
      final queue = switch (queueResult) {
        Success<List<ContributionModel>>(:final value) => value,
        Failure<List<ContributionModel>>() => fail('Expected success'),
      };
      expect(queue.single.triageSuggestion, isNotNull);
      expect(
        queue.single.triageSuggestion!.label,
        'AI suggestion, not validated.',
      );

      final provenanceResult = await repository.fetchReviewProvenance(
        'queue-item',
      );
      final provenance = switch (provenanceResult) {
        Success<List<ProvenanceTimelineEntry>>(:final value) => value,
        Failure<List<ProvenanceTimelineEntry>>() => fail('Expected success'),
      };
      expect(provenance, hasLength(1));
      expect(provenance.single.safeActorLabel, 'Curator Reviewer');
      expect(
        provenance.single.metadata.map((field) => field.label),
        contains('Status'),
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        isNot(contains('Private note')),
      );
      expect(
        provenance.single.metadata.map((field) => field.label),
        isNot(contains('Raw Response')),
      );
    },
  );

  test(
    'remote review repository surfaces 403 authorization failures',
    () async {
      final client = MockClient((request) async {
        if (request.method == 'POST' &&
            request.url.path.endsWith('/reviews/queue-item/approve')) {
          return jsonResponse({
            'success': false,
            'message': 'You do not have permission to perform this action.',
            'errors': {},
          }, 403);
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteReviewRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenResolver: () async => 'test-token',
      );

      final result = await repository.approveContribution(
        'queue-item',
        'Approved for publication workflow.',
      );

      expect(result, isA<Failure<void>>());
      final failure = result as Failure<void>;
      expect(
        failure.message,
        'You do not have permission to perform this action.',
      );
    },
  );

  test('remote knowledge repository parses semantic search results', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET' &&
          request.url.path.endsWith('/search/semantic')) {
        expect(request.url.queryParameters['q'], 'gangsa');
        return jsonResponse({
          'success': true,
          'message': 'OK',
          'data': [
            {
              'result_type': 'knowledge_item',
              'match_type': 'semantic',
              'knowledge_item': {
                'id': 'knowledge-uuid',
                'slug': 'gangsa',
                'title': 'Gangsa',
                'description': 'Metallophone',
                'knowledge_type': 'instrument',
                'knowledge_type_label': 'Instrument',
                'gamelan_type': 'gong_kebyar',
                'gamelan_type_label': 'Gong Kebyar',
                'source_summary': 'Published summary',
              },
            },
          ],
        });
      }
      return jsonResponse({'success': false, 'message': 'Not found'}, 404);
    });

    final repository = RemoteKnowledgeRepository(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: client,
      ),
    );

    final result = await repository.searchKnowledge(query: 'gangsa');
    final searchResult = switch (result) {
      Success<KnowledgeSearchResult>(:final value) => value,
      Failure<KnowledgeSearchResult>() => fail('Expected success'),
    };

    final items = searchResult.items;
    expect(items, hasLength(1));
    expect(items.single.title, 'Gangsa');
    expect(items.single.knowledgeType, 'Instrument');
    expect(searchResult.usedSemanticSearch, isTrue);
    expect(searchResult.fellBackToKeyword, isFalse);
    expect(searchResult.notice, isNull);
  });

  test(
    'remote knowledge repository falls back to keyword search on semantic 503',
    () async {
      final requestedPaths = <String>[];
      final client = MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.method == 'GET' &&
            request.url.path.endsWith('/search/semantic')) {
          expect(request.url.queryParameters['q'], 'gangsa');
          return jsonResponse({
            'success': false,
            'message': 'Semantic search is temporarily unavailable.',
            'errors': <String, Object?>{},
          }, 503);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/search')) {
          expect(request.url.queryParameters['q'], 'gangsa');
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': [
              {
                'result_type': 'knowledge_item',
                'match_type': 'keyword',
                'knowledge_item': {
                  'id': 'keyword-uuid',
                  'slug': 'gangsa-keyword',
                  'title': 'Gangsa keyword result',
                  'description': 'Metallophone',
                  'knowledge_type': 'instrument',
                  'knowledge_type_label': 'Instrument',
                  'gamelan_type': 'gong_kebyar',
                  'gamelan_type_label': 'Gong Kebyar',
                  'source_summary': 'Published summary',
                },
              },
            ],
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteKnowledgeRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
      );

      final result = await repository.searchKnowledge(query: 'gangsa');
      final searchResult = switch (result) {
        Success<KnowledgeSearchResult>(:final value) => value,
        Failure<KnowledgeSearchResult>() => fail('Expected success'),
      };

      expect(requestedPaths, ['/api/v1/search/semantic', '/api/v1/search']);
      expect(searchResult.items, hasLength(1));
      expect(searchResult.items.single.title, 'Gangsa keyword result');
      expect(searchResult.usedSemanticSearch, isFalse);
      expect(searchResult.fellBackToKeyword, isTrue);
      expect(
        searchResult.notice,
        'Semantic search is temporarily unavailable. Showing keyword results instead.',
      );
    },
  );

  test(
    'remote knowledge repository does not fall back on semantic 403',
    () async {
      var keywordRequested = false;
      final client = MockClient((request) async {
        if (request.method == 'GET' &&
            request.url.path.endsWith('/search/semantic')) {
          return jsonResponse({
            'success': false,
            'message': 'You do not have permission to perform this action.',
            'errors': <String, Object?>{},
          }, 403);
        }
        if (request.method == 'GET' && request.url.path.endsWith('/search')) {
          keywordRequested = true;
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = RemoteKnowledgeRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
      );

      final result = await repository.searchKnowledge(query: 'gangsa');
      final failure = switch (result) {
        Success<KnowledgeSearchResult>() => fail('Expected failure'),
        Failure<KnowledgeSearchResult>(:final message) => message,
      };

      expect(keywordRequested, isFalse);
      expect(failure, 'You do not have permission to perform this action.');
    },
  );
}

http.Response jsonResponse(Map<String, Object?> body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

String? headerValue(http.BaseRequest request, String name) {
  final normalized = name.toLowerCase();
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value;
    }
  }
  return null;
}
