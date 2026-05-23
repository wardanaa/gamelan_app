import '../../../core/api/api_client.dart';
import '../../../core/api/api_parsers.dart';
import '../../../core/api/repository_errors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/result.dart';
import 'ontology_class.dart';
import 'ontology_entity.dart';
import 'ontology_entity_page.dart';
import 'ontology_property.dart';
import 'ontology_repository.dart';

typedef TokenResolver = Future<String?> Function();

class RemoteOntologyRepository implements OntologyRepository {
  RemoteOntologyRepository({
    required ApiClient apiClient,
    required TokenResolver tokenResolver,
  }) : _apiClient = apiClient,
       _tokenResolver = tokenResolver;

  final ApiClient _apiClient;
  final TokenResolver _tokenResolver;

  @override
  Future<Result<List<OntologyClass>>> getClasses() async {
    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.ontologyClasses,
        token: token,
      );
      final classes = OntologyClass.listFromApi(
        _listPayload(response, const ['classes', 'ontology_classes']),
      );
      if (classes.isEmpty) {
        return const Failure('The server returned no ontology classes.');
      }
      return Success(classes);
    });
  }

  @override
  Future<Result<List<OntologyProperty>>> getProperties() async {
    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.ontologyProperties,
        token: token,
      );
      final properties = OntologyProperty.listFromApi(
        _listPayload(response, const ['properties', 'ontology_properties']),
      );
      if (properties.isEmpty) {
        return const Failure('The server returned no ontology properties.');
      }
      return Success(properties);
    });
  }

  @override
  Future<Result<OntologyEntityPage>> getEntities({
    String? type,
    int page = 1,
    int perPage = 10,
  }) async {
    return _run((token) async {
      final queryParameters = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      final normalizedType = type?.trim();
      if (normalizedType != null && normalizedType.isNotEmpty) {
        queryParameters['type'] = normalizedType;
      }

      final response = await _apiClient.getJson(
        ApiEndpoints.ontologyEntities,
        token: token,
        queryParameters: queryParameters,
      );
      final entities = OntologyEntity.listFromApi(
        _listPayload(response, const ['entities', 'ontology_entities']),
      );
      if (entities.isEmpty) {
        return const Failure('The server returned no ontology entities.');
      }

      final paginationMeta =
          response.paginationMeta ??
          ApiPaginationMeta(
            currentPage: page < 1 ? 1 : page,
            perPage: perPage < 1 ? 1 : perPage,
            total: entities.length,
          );
      return Success(
        OntologyEntityPage(entities: entities, paginationMeta: paginationMeta),
      );
    });
  }

  @override
  Future<Result<OntologyEntity?>> getEntity(String id) async {
    return _run((token) async {
      try {
        final response = await _apiClient.getJson(
          ApiEndpoints.ontologyEntity(id),
          token: token,
        );
        final entity = OntologyEntity.fromApi(
          _nestedEntityPayload(response.dataMap),
        );
        if (entity == null) {
          return const Failure(
            'The server returned an invalid ontology entity.',
          );
        }
        return Success(entity);
      } on ApiException catch (exception) {
        if (exception.statusCode == 404) {
          return const Success(null);
        }
        rethrow;
      }
    });
  }

  Object? _listPayload(ApiResponse response, List<String> nestedKeys) {
    final data = response.data;
    if (data is Iterable) {
      return data;
    }

    final map = response.dataMap;
    for (final key in nestedKeys) {
      final nested = map[key];
      if (nested is Iterable) {
        return nested;
      }
      if (nested is Map<String, Object?>) {
        for (final nestedKey in nestedKeys) {
          final nestedValue = nested[nestedKey];
          if (nestedValue is Iterable) {
            return nestedValue;
          }
        }
      }
    }

    final nestedData = map['data'];
    if (nestedData is Iterable) {
      return nestedData;
    }
    if (nestedData is Map<String, Object?>) {
      for (final key in nestedKeys) {
        final nested = nestedData[key];
        if (nested is Iterable) {
          return nested;
        }
      }
    }

    return data;
  }

  Map<String, Object?> _nestedEntityPayload(Map<String, Object?> data) {
    final nested = nestedObject(data, const [
      'entity',
      'ontology_entity',
      'knowledge_item',
    ]);
    return nested ?? data;
  }

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(String token) action,
  ) async {
    final token = await _tokenResolver();
    if (token == null || token.isEmpty) {
      return const Failure('Please sign in to continue.');
    }

    try {
      return await action(token);
    } on ApiException catch (exception) {
      return Failure(messageFromApiException(exception), exception: exception);
    } on FormatException catch (exception) {
      return Failure(
        'The server returned an invalid response.',
        exception: exception,
      );
    } on Object catch (exception) {
      return Failure('Unable to reach the server.', exception: exception);
    }
  }
}
