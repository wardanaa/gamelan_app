import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/media_asset_model.dart';
import 'package:gamelan_app/features/contributions/data/remote_contribution_repository.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_item.dart';
import 'package:gamelan_app/features/knowledge/data/remote_knowledge_repository.dart';
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
  });

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

  test('remote knowledge repository parses search results', () async {
    final client = MockClient((request) async {
      if (request.method == 'GET' && request.url.path.endsWith('/search')) {
        expect(request.url.queryParameters['q'], 'gangsa');
        return jsonResponse({
          'success': true,
          'message': 'OK',
          'data': [
            {
              'result_type': 'knowledge_item',
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
    final items = switch (result) {
      Success<List<KnowledgeItem>>(:final value) => value,
      Failure<List<KnowledgeItem>>() => fail('Expected success'),
    };

    expect(items, hasLength(1));
    expect(items.single.title, 'Gangsa');
    expect(items.single.knowledgeType, 'Instrument');
  });
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
