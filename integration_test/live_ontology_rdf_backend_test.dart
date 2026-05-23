import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/constants/api_endpoints.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:gamelan_app/features/auth/data/auth_session.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = LiveOntologyRdfBackendConfig.fromDartDefines();

  if (config == null) {
    testWidgets(
      'live ontology/RDF backend verification skipped: set GAMELAN_TEST_API_BASE_URL, GAMELAN_TEST_EMAIL, and GAMELAN_TEST_PASSWORD with --dart-define',
      (WidgetTester tester) async {},
      skip: true,
    );
    return;
  }

  testWidgets(
    'live ontology endpoints expose published classes, properties, and entities',
    (WidgetTester tester) async {
      final context = await _signInCurator(config);
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final classesResponse = await context.apiClient.getJson(
        '/ontology/classes',
        token: context.session.accessToken,
      );
      final classes = _listFromData(
        classesResponse.data,
        fallbackKeys: const ['ontology_classes', 'classes', 'results', 'items'],
      );

      expect(classes, isNotEmpty);
      expect(
        _hasAnyLabel(classes, const ['instrument', 'ensemble']),
        isTrue,
        reason:
            'The ontology class endpoint should return public MVP mapping classes for curator selection.',
      );

      final propertiesResponse = await context.apiClient.getJson(
        '/ontology/properties',
        token: context.session.accessToken,
      );
      final properties = _listFromData(
        propertiesResponse.data,
        fallbackKeys: const [
          'ontology_properties',
          'properties',
          'results',
          'items',
        ],
      );

      expect(properties, isNotEmpty);
      expect(
        _hasAnyLabel(properties, const ['usedinensemble', 'derivedfromsource']),
        isTrue,
        reason:
            'The ontology property endpoint should return published object properties used for RDF mapping.',
      );

      final entitiesResponse = await context.apiClient.getJson(
        '/ontology/entities',
        token: context.session.accessToken,
      );
      final entities = _listFromData(
        entitiesResponse.data,
        fallbackKeys: const [
          'ontology_entities',
          'entities',
          'results',
          'items',
        ],
      );

      expect(entities, isNotEmpty);
      final firstEntity = entities.first;
      expect(_stringFrom(firstEntity, const ['label', 'name']), isNotEmpty);
      expect(_stringFrom(firstEntity, const ['uri']), isNotEmpty);

      final publicEntityUuid = config.publicOntologyEntityUuid;
      if (publicEntityUuid != null && publicEntityUuid.trim().isNotEmpty) {
        final entityResponse = await context.apiClient.getJson(
          '/ontology/entities/$publicEntityUuid',
          token: context.session.accessToken,
        );
        final entity =
            _mapFrom(entityResponse.dataMap['ontology_entity']) ??
            _mapFrom(entityResponse.dataMap['entity']) ??
            entityResponse.dataMap;
        expect(_stringFrom(entity, const ['id', 'uuid']), isNotEmpty);
        expect(_stringFrom(entity, const ['label', 'name']), isNotEmpty);
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  testWidgets(
    'live RDF publication queues eligible contributions as pending publication jobs',
    (WidgetTester tester) async {
      final eligibleContributionUuid = config.eligibleContributionUuid;
      if (eligibleContributionUuid == null ||
          eligibleContributionUuid.trim().isEmpty) {
        return;
      }

      final context = await _signInCurator(config);
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final contribution = await _fetchContribution(
        context.apiClient,
        context.session.accessToken,
        eligibleContributionUuid,
      );
      final contributionStatus = _stringFrom(contribution, const ['status']);
      expect(
        contributionStatus,
        anyOf('curator_approved', 'expert_approved'),
        reason:
            'The RDF publication fixture must already be curator or expert approved.',
      );
      expect(
        _boolFrom(contribution, const ['cultural_sensitivity']),
        isFalse,
        reason:
            'The RDF publication fixture must be non-sensitive to enter the public graph.',
      );

      final payload = _rdfPublicationPayloadFromContribution(contribution);
      final publicationResponse = await context.apiClient.postJson(
        '/contributions/$eligibleContributionUuid/rdf-publications',
        token: context.session.accessToken,
        body: payload,
      );
      final rdfPublication =
          _mapFrom(publicationResponse.dataMap['rdf_publication']) ??
          _mapFrom(publicationResponse.dataMap['rdfPublication']) ??
          publicationResponse.dataMap;
      expect(
        _stringFrom(rdfPublication, const ['status']),
        'pending',
        reason:
            'Queueing RDF publication should create a pending publication record before the triplestore job completes.',
      );
      expect(_stringFrom(rdfPublication, const ['id', 'uuid']), isNotEmpty);
      expect(
        _stringFrom(rdfPublication, const ['rdf_subject_uri']),
        isNotEmpty,
      );
      expect(
        _stringFrom(rdfPublication, const ['rdf_graph_uri']),
        contains('graph'),
      );

      final metadata = _mapFrom(rdfPublication['metadata']);
      expect(metadata, isNotNull);
      expect(_stringFrom(metadata!, const ['ontology_class']), isNotEmpty);
      expect(
        _intFrom(metadata, const ['relations_count']),
        greaterThanOrEqualTo(0),
      );

      final publishedBy = _mapFrom(rdfPublication['published_by']);
      expect(publishedBy, isNotNull);
      expect(_stringFrom(publishedBy!, const ['name']), isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 60)),
    skip:
        config.eligibleContributionUuid == null ||
        config.eligibleContributionUuid!.trim().isEmpty,
  );

  testWidgets(
    'live RDF publication rejects culturally sensitive contributions with a safe client message',
    (WidgetTester tester) async {
      final sensitiveUuid = config.sensitiveContributionUuid;
      if (sensitiveUuid == null || sensitiveUuid.trim().isEmpty) {
        return;
      }

      final context = await _signInCurator(config);
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final contribution = await _fetchContribution(
        context.apiClient,
        context.session.accessToken,
        sensitiveUuid,
      );
      expect(
        _boolFrom(contribution, const ['cultural_sensitivity']),
        isTrue,
        reason:
            'The sensitive fixture must be culturally sensitive so the publication guard is exercised.',
      );

      final exception = await _expectApiException(
        () => context.apiClient.postJson(
          '/contributions/$sensitiveUuid/rdf-publications',
          token: context.session.accessToken,
          body: _rdfPublicationPayloadFromContribution(contribution),
        ),
      );

      expect(
        exception.statusCode,
        anyOf(403, 422),
        reason:
            'Sensitive contributions should be rejected with a safe authorization or validation response.',
      );
      expect(exception.message.trim(), isNotEmpty);
      expect(exception.message.toLowerCase(), isNot(contains('select')));
      expect(exception.message.toLowerCase(), isNot(contains('sparql')));
    },
    timeout: const Timeout(Duration(seconds: 60)),
    skip:
        config.sensitiveContributionUuid == null ||
        config.sensitiveContributionUuid!.trim().isEmpty,
  );

  testWidgets(
    'live RDF publication rejects ineligible contribution statuses with a safe client message',
    (WidgetTester tester) async {
      final ineligibleUuid = config.ineligibleContributionUuid;
      if (ineligibleUuid == null || ineligibleUuid.trim().isEmpty) {
        return;
      }

      final context = await _signInCurator(config);
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final contribution = await _fetchContribution(
        context.apiClient,
        context.session.accessToken,
        ineligibleUuid,
      );
      final contributionStatus = _stringFrom(contribution, const ['status']);
      expect(
        contributionStatus,
        isNot(anyOf('curator_approved', 'expert_approved')),
        reason:
            'The ineligible fixture must not already be approved for RDF publication.',
      );

      final exception = await _expectApiException(
        () => context.apiClient.postJson(
          '/contributions/$ineligibleUuid/rdf-publications',
          token: context.session.accessToken,
          body: _rdfPublicationPayloadFromContribution(contribution),
        ),
      );

      expect(
        exception.statusCode,
        anyOf(403, 422),
        reason:
            'Ineligible contributions should be rejected without exposing internal publication details.',
      );
      expect(exception.message.trim(), isNotEmpty);
      expect(exception.message.toLowerCase(), isNot(contains('sql')));
    },
    timeout: const Timeout(Duration(seconds: 60)),
    skip:
        config.ineligibleContributionUuid == null ||
        config.ineligibleContributionUuid!.trim().isEmpty,
  );

  testWidgets(
    'live RDF publication rejects self-publication by the original contributor',
    (WidgetTester tester) async {
      final contributorEmail = config.selfPublishContributorEmail;
      final contributorPassword = config.selfPublishContributorPassword;
      final selfPublishUuid = config.selfPublishContributionUuid;

      if (contributorEmail == null ||
          contributorEmail.trim().isEmpty ||
          contributorPassword == null ||
          contributorPassword.trim().isEmpty ||
          selfPublishUuid == null ||
          selfPublishUuid.trim().isEmpty) {
        return;
      }

      final context = await _signInContributor(
        config,
        email: contributorEmail,
        password: contributorPassword,
      );
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final contribution = await _fetchContribution(
        context.apiClient,
        context.session.accessToken,
        selfPublishUuid,
      );

      final exception = await _expectApiException(
        () => context.apiClient.postJson(
          '/contributions/$selfPublishUuid/rdf-publications',
          token: context.session.accessToken,
          body: _rdfPublicationPayloadFromContribution(contribution),
        ),
      );

      expect(
        exception.statusCode,
        anyOf(403, 422),
        reason:
            'The original contributor must not be able to queue their own RDF publication.',
      );
      expect(exception.message.trim(), isNotEmpty);
    },
    timeout: const Timeout(Duration(seconds: 60)),
    skip:
        config.selfPublishContributionUuid == null ||
        config.selfPublishContributionUuid!.trim().isEmpty ||
        config.selfPublishContributorEmail == null ||
        config.selfPublishContributorEmail!.trim().isEmpty ||
        config.selfPublishContributorPassword == null ||
        config.selfPublishContributorPassword!.trim().isEmpty,
  );

  testWidgets(
    'live SPARQL proxy rejects raw queries and accepts only predefined query keys',
    (WidgetTester tester) async {
      final context = await _signInCurator(config);
      addTearDown(context.dispose);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final rawQueryException = await _expectApiException(
        () => context.apiClient.postJson(
          '/sparql/query',
          token: context.session.accessToken,
          body: const {'query': 'SELECT * WHERE { ?s ?p ?o } LIMIT 1'},
        ),
      );

      expect(
        rawQueryException.statusCode,
        anyOf(400, 403, 422),
        reason: 'The protected SPARQL proxy must not accept raw SPARQL text.',
      );
      expect(rawQueryException.message.trim(), isNotEmpty);
      expect(
        rawQueryException.message.toLowerCase(),
        isNot(contains('select')),
      );

      final publishedEntitiesResponse = await context.apiClient.postJson(
        '/sparql/query',
        token: context.session.accessToken,
        body: const {
          'query_key': 'published_entities_by_type',
          'parameters': {'ontology_class': 'Instrument', 'limit': 5},
        },
      );

      final results = _sparqlResultsFrom(publishedEntitiesResponse.data);
      expect(results, isNotEmpty);
      for (final result in results) {
        final safeResult = _mapFrom(result) ?? result;
        expect(safeResult, isNotNull);
        expect(
          _containsForbiddenPublicationKeys(safeResult),
          isFalse,
          reason:
              'SPARQL proxy responses must stay within the public knowledge projection.',
        );
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}

class LiveOntologyRdfBackendConfig {
  const LiveOntologyRdfBackendConfig({
    required this.apiBaseUrl,
    required this.email,
    required this.password,
    this.publicOntologyEntityUuid,
    this.eligibleContributionUuid,
    this.ineligibleContributionUuid,
    this.sensitiveContributionUuid,
    this.selfPublishContributionUuid,
    this.selfPublishContributorEmail,
    this.selfPublishContributorPassword,
  });

  final String apiBaseUrl;
  final String email;
  final String password;
  final String? publicOntologyEntityUuid;
  final String? eligibleContributionUuid;
  final String? ineligibleContributionUuid;
  final String? sensitiveContributionUuid;
  final String? selfPublishContributionUuid;
  final String? selfPublishContributorEmail;
  final String? selfPublishContributorPassword;

  static LiveOntologyRdfBackendConfig? fromDartDefines() {
    final apiBaseUrl = _dartDefineValue(_apiBaseUrl);
    final email = _dartDefineValue(_email);
    final password = _dartDefineValue(_password);

    if (apiBaseUrl == null || email == null || password == null) {
      return null;
    }

    return LiveOntologyRdfBackendConfig(
      apiBaseUrl: apiBaseUrl,
      email: email,
      password: password,
      publicOntologyEntityUuid: _dartDefineValue(_publicOntologyEntityUuid),
      eligibleContributionUuid: _dartDefineValue(_eligibleContributionUuid),
      ineligibleContributionUuid: _dartDefineValue(_ineligibleContributionUuid),
      sensitiveContributionUuid: _dartDefineValue(_sensitiveContributionUuid),
      selfPublishContributionUuid: _dartDefineValue(
        _selfPublishContributionUuid,
      ),
      selfPublishContributorEmail: _dartDefineValue(
        _selfPublishContributorEmail,
      ),
      selfPublishContributorPassword: _dartDefineValue(
        _selfPublishContributorPassword,
      ),
    );
  }

  static const String _apiBaseUrl = String.fromEnvironment(
    'GAMELAN_TEST_API_BASE_URL',
  );
  static const String _email = String.fromEnvironment('GAMELAN_TEST_EMAIL');
  static const String _password = String.fromEnvironment(
    'GAMELAN_TEST_PASSWORD',
  );
  static const String _publicOntologyEntityUuid = String.fromEnvironment(
    'GAMELAN_TEST_PUBLIC_ONTOLOGY_ENTITY_UUID',
  );
  static const String _eligibleContributionUuid = String.fromEnvironment(
    'GAMELAN_TEST_RDF_ELIGIBLE_CONTRIBUTION_UUID',
  );
  static const String _ineligibleContributionUuid = String.fromEnvironment(
    'GAMELAN_TEST_RDF_INELIGIBLE_CONTRIBUTION_UUID',
  );
  static const String _sensitiveContributionUuid = String.fromEnvironment(
    'GAMELAN_TEST_RDF_SENSITIVE_CONTRIBUTION_UUID',
  );
  static const String _selfPublishContributionUuid = String.fromEnvironment(
    'GAMELAN_TEST_RDF_SELF_PUBLISH_CONTRIBUTION_UUID',
  );
  static const String _selfPublishContributorEmail = String.fromEnvironment(
    'GAMELAN_TEST_RDF_SELF_PUBLISH_EMAIL',
  );
  static const String _selfPublishContributorPassword = String.fromEnvironment(
    'GAMELAN_TEST_RDF_SELF_PUBLISH_PASSWORD',
  );

  static String? _dartDefineValue(String value) {
    final trimmedValue = value.trim();
    if (trimmedValue.isEmpty) {
      return null;
    }
    return trimmedValue;
  }
}

class _AuthenticatedBackendSession {
  _AuthenticatedBackendSession({
    required this.apiClient,
    required this.session,
    required this.httpClient,
  });

  final ApiClient apiClient;
  final AuthSession session;
  final http.Client httpClient;

  Future<void> dispose() async {
    httpClient.close();
  }
}

Future<_AuthenticatedBackendSession> _signInCurator(
  LiveOntologyRdfBackendConfig config,
) async {
  SharedPreferences.setMockInitialValues({});
  final httpClient = http.Client();
  final tokenStorage = TokenStorage(backend: MemoryTokenStorageBackend());
  final apiClient = ApiClient(
    baseUrl: config.apiBaseUrl,
    httpClient: httpClient,
  );
  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  final signInResult = await authRepository.signIn(
    email: config.email,
    password: config.password,
  );

  final session = switch (signInResult) {
    Success<AuthSession>(:final value) => value,
    Failure<AuthSession>(:final message) => fail(message),
  };

  expect(
    session.roles,
    isNotEmpty,
    reason:
        'The live ontology/RDF verification suite requires a curator or admin account with backend roles.',
  );
  expect(
    session.roles,
    anyOf(contains('curator'), contains('admin')),
    reason:
        'The ontology and RDF publication endpoints must be exercised as a curator or admin user.',
  );

  return _AuthenticatedBackendSession(
    apiClient: apiClient,
    session: session,
    httpClient: httpClient,
  );
}

Future<_AuthenticatedBackendSession> _signInContributor(
  LiveOntologyRdfBackendConfig config, {
  required String email,
  required String password,
}) async {
  SharedPreferences.setMockInitialValues({});
  final httpClient = http.Client();
  final tokenStorage = TokenStorage(backend: MemoryTokenStorageBackend());
  final apiClient = ApiClient(
    baseUrl: config.apiBaseUrl,
    httpClient: httpClient,
  );
  final authRepository = AuthRepository(
    apiClient: apiClient,
    tokenStorage: tokenStorage,
  );

  final signInResult = await authRepository.signIn(
    email: email,
    password: password,
  );

  final session = switch (signInResult) {
    Success<AuthSession>(:final value) => value,
    Failure<AuthSession>(:final message) => fail(message),
  };

  return _AuthenticatedBackendSession(
    apiClient: apiClient,
    session: session,
    httpClient: httpClient,
  );
}

Future<Map<String, Object?>> _fetchContribution(
  ApiClient apiClient,
  String token,
  String contributionUuid,
) async {
  final response = await apiClient.getJson(
    ApiEndpoints.contribution(contributionUuid),
    token: token,
  );
  final contribution =
      _mapFrom(response.dataMap['contribution']) ??
      _mapFrom(response.dataMap['review']) ??
      response.dataMap;

  return contribution;
}

Map<String, Object?> _rdfPublicationPayloadFromContribution(
  Map<String, Object?> contribution,
) {
  final title = _stringFrom(contribution, const ['title']) ?? 'Untitled';
  final knowledgeType =
      _stringFrom(contribution, const [
        'knowledge_type_label',
        'knowledgeTypeLabel',
      ]) ??
      _stringFrom(contribution, const ['knowledge_type', 'knowledgeType']) ??
      'Instrument';
  final subjectSlug = _slugify(
    _stringFrom(contribution, const ['slug']) ?? title,
  );
  final preferredLabel = title;
  final sourceSummary =
      _stringFrom(contribution, const ['source_note', 'sourceNote']) ??
      _stringFrom(contribution, const ['description']) ??
      'Community source note.';
  final language = _stringFrom(contribution, const ['language']) ?? 'id';
  final relations = _relationsFromContribution(contribution);

  return <String, Object?>{
    'ontology_class': _ontologyClassFromKnowledgeType(knowledgeType),
    'subject_slug': subjectSlug,
    'preferred_label': preferredLabel,
    'language': language,
    'source_summary': sourceSummary,
    'relations': relations,
  };
}

List<Map<String, Object?>> _relationsFromContribution(
  Map<String, Object?> contribution,
) {
  final relatedEntities = _listFromData(
    contribution['related_entities'],
    fallbackKeys: const ['relations', 'relatedEntities'],
  );
  if (relatedEntities.isNotEmpty) {
    final relation = relatedEntities.first;
    final property =
        _stringFrom(relation, const [
          'property',
          'relation',
          'relation_type',
        ]) ??
        'derivedFromSource';
    final objectLabel =
        _stringFrom(relation, const ['object_label', 'label', 'name']) ??
        'Community source';
    final objectSlug = _slugify(
      _stringFrom(relation, const ['object_slug', 'slug']) ?? objectLabel,
    );
    final objectClass =
        _stringFrom(relation, const ['object_class', 'class', 'entity_type']) ??
        'Source';

    return <Map<String, Object?>>[
      <String, Object?>{
        'property': property,
        'object_slug': objectSlug,
        'object_label': objectLabel,
        'object_class': objectClass,
      },
    ];
  }

  return <Map<String, Object?>>[
    <String, Object?>{
      'property': 'derivedFromSource',
      'object_slug': 'community-source-note',
      'object_label': 'Community source note',
      'object_class': 'Source',
    },
  ];
}

String _ontologyClassFromKnowledgeType(String knowledgeType) {
  final normalized = knowledgeType.trim().toLowerCase().replaceAll(' ', '_');
  return switch (normalized) {
    'instrument' => 'Instrument',
    'ensemble' => 'Ensemble',
    'composition' => 'Composition',
    'performance' => 'Performance',
    'technique' => 'Technique',
    'person' => 'Person',
    'group' => 'Group',
    'place' => 'Place',
    'mediaasset' || 'media_asset' || 'media' => 'MediaAsset',
    'source' => 'Source',
    'term' => 'Term',
    'contribution' => 'Contribution',
    'validation' => 'Validation',
    _ => 'Instrument',
  };
}

String _slugify(String value) {
  final normalized = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');
  return normalized.isEmpty ? 'untitled' : normalized;
}

Future<ApiException> _expectApiException(
  Future<ApiResponse> Function() action,
) async {
  try {
    await action();
    fail('Expected the live backend to reject the request.');
  } on ApiException catch (exception) {
    return exception;
  }
}

Map<String, Object?>? _mapFrom(Object? value) {
  if (value is Map<String, Object?>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', value));
  }
  return null;
}

List<Map<String, Object?>> _listFromData(
  Object? data, {
  required List<String> fallbackKeys,
}) {
  if (data is Iterable) {
    return data.map(_mapFrom).whereType<Map<String, Object?>>().toList();
  }
  if (data is Map) {
    final map = _mapFrom(data);
    if (map == null) {
      return const [];
    }
    for (final key in fallbackKeys) {
      final nested = _listFromData(map[key], fallbackKeys: const []);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
  }
  return const [];
}

List<String> _labelsFromMaps(List<Map<String, Object?>> maps) {
  final labels = <String>[];
  for (final map in maps) {
    final label = _stringFrom(map, const ['label', 'name', 'title', 'uri']);
    if (label != null && label.trim().isNotEmpty) {
      labels.add(label.trim());
    }
  }
  return labels;
}

bool _hasAnyLabel(List<Map<String, Object?>> maps, List<String> expected) {
  final labels = _labelsFromMaps(
    maps,
  ).map((label) => label.toLowerCase()).toList(growable: false);
  return expected.any((candidate) {
    final normalizedCandidate = candidate.toLowerCase();
    return labels.any(
      (label) =>
          label == normalizedCandidate ||
          label.contains(normalizedCandidate) ||
          normalizedCandidate.contains(label),
    );
  });
}

String? _stringFrom(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return null;
}

bool _boolFrom(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is bool) {
      return value;
    }
  }
  return false;
}

int _intFrom(Map<String, Object?> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return 0;
}

List<Map<String, Object?>> _sparqlResultsFrom(Object? data) {
  if (data is Iterable) {
    return data.map(_mapFrom).whereType<Map<String, Object?>>().toList();
  }
  if (data is Map) {
    final map = _mapFrom(data);
    if (map == null) {
      return const [];
    }
    for (final key in const [
      'results',
      'items',
      'bindings',
      'knowledge_items',
      'entities',
      'data',
    ]) {
      final nested = _sparqlResultsFrom(map[key]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }
    return <Map<String, Object?>>[map];
  }
  return const [];
}

bool _containsForbiddenPublicationKeys(Map<String, Object?> map) {
  const forbiddenKeys = {
    'sparql',
    'query',
    'query_text',
    'query_result',
    'sql',
    'stack_trace',
    'credentials',
    'password',
    'private_note',
    'storage_disk',
    'file_path',
    'file_url',
    'raw_ai',
  };

  bool visit(Object? value) {
    if (value is Map) {
      final normalized = _mapFrom(value);
      if (normalized == null) {
        return false;
      }
      if (normalized.keys.any(
        (key) => forbiddenKeys.contains(key.toLowerCase()),
      )) {
        return true;
      }
      return normalized.values.any(visit);
    }
    if (value is Iterable) {
      return value.any(visit);
    }
    return false;
  }

  return visit(map);
}

class MemoryTokenStorageBackend implements TokenStorageBackend {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }

  @override
  Future<String?> read({required String key}) async {
    return _values[key];
  }

  @override
  Future<void> delete({required String key}) async {
    _values.remove(key);
  }
}
