import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/contributions/data/contribution_model.dart';
import 'package:gamelan_app/features/contributions/data/contribution_repository.dart';
import 'package:gamelan_app/features/contributions/data/remote_contribution_repository.dart';
import 'package:gamelan_app/features/knowledge/data/knowledge_item.dart';
import 'package:gamelan_app/features/knowledge/data/remote_knowledge_repository.dart';
import 'package:gamelan_app/features/review/data/remote_review_repository.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('remote contribution repository parses list and create responses', () async {
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
      apiClient: ApiClient(baseUrl: 'http://localhost/api/v1', httpClient: client),
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
      apiClient: ApiClient(baseUrl: 'http://localhost/api/v1', httpClient: client),
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
            },
          ],
        });
      }
      if (request.method == 'POST' &&
          request.url.path.endsWith('/reviews/queue-item/approve')) {
        approveCalled = true;
        final body = jsonDecode(request.body) as Map<String, Object?>;
        expect(body['note'], 'Approved for publication workflow.');
        return jsonResponse({'success': true, 'message': 'Approved', 'data': {}});
      }
      return jsonResponse({'success': false, 'message': 'Not found'}, 404);
    });

    final repository = RemoteReviewRepository(
      apiClient: ApiClient(baseUrl: 'http://localhost/api/v1', httpClient: client),
      tokenResolver: () async => 'test-token',
    );

    final queueResult = await repository.fetchReviewQueue();
    expect(queueResult, isA<Success<List<ContributionModel>>>());

    final approveResult = await repository.approveContribution(
      'queue-item',
      'Approved for publication workflow.',
    );
    expect(approveResult, isA<Success<void>>());
    expect(approveCalled, isTrue);
  });

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
      apiClient: ApiClient(baseUrl: 'http://localhost/api/v1', httpClient: client),
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
