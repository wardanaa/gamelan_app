import '../../contributions/data/remote_contribution_repository.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_parsers.dart';
import '../../../core/api/repository_errors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import 'knowledge_item.dart';
import 'knowledge_repository.dart';

class RemoteKnowledgeRepository implements KnowledgeRepository {
  RemoteKnowledgeRepository({
    required ApiClient apiClient,
    TokenResolver? tokenResolver,
    TaxonomyMapper? taxonomyMapper,
  }) : _apiClient = apiClient,
       _tokenResolver = tokenResolver,
       _taxonomyMapper = taxonomyMapper ?? TaxonomyMapper();

  final ApiClient _apiClient;
  final TokenResolver? _tokenResolver;
  final TaxonomyMapper _taxonomyMapper;

  @override
  Future<Result<List<KnowledgeItem>>> fetchKnowledgeItems() async {
    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.knowledgeItems,
        token: token,
        queryParameters: const {'per_page': '50'},
      );
      return Success(
        KnowledgeItem.listFromApi(response.data, taxonomy: _taxonomyMapper),
      );
    });
  }

  @override
  Future<Result<KnowledgeItem?>> findKnowledgeItem(String id) async {
    return _run((token) async {
      try {
        final response = await _apiClient.getJson(
          ApiEndpoints.knowledgeItem(id),
          token: token,
        );
        return Success(
          KnowledgeItem.fromApi(response.dataMap, taxonomy: _taxonomyMapper),
        );
      } on ApiException catch (exception) {
        if (exception.statusCode == 404) {
          return const Success(null);
        }
        rethrow;
      }
    });
  }

  @override
  Future<Result<List<KnowledgeItem>>> searchKnowledge({
    required String query,
    String? gamelanType,
    String? knowledgeType,
    String? gamelanTypeSlug,
    String? knowledgeTypeSlug,
  }) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      return fetchKnowledgeItems();
    }

    final gamelanSlug =
        gamelanTypeSlug ??
        (gamelanType == null
            ? null
            : _taxonomyMapper.gamelanSlugFromLabel(gamelanType));
    final knowledgeSlug =
        knowledgeTypeSlug ??
        (knowledgeType == null
            ? null
            : _taxonomyMapper.knowledgeSlugFromLabel(knowledgeType));

    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.search,
        token: token,
        queryParameters: {
          'q': normalizedQuery,
          if (gamelanSlug != null) 'gamelan_type': gamelanSlug,
          if (knowledgeSlug != null) 'knowledge_type': knowledgeSlug,
          'per_page': '50',
        },
      );
      return Success(_searchResultsFromApi(response.data));
    });
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchKnowledgeTypes() async {
    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.knowledgeTypes,
        token: token,
      );
      final options = TaxonomyMapper.optionsFromApiList(response.data);
      return Success(
        options.isEmpty
            ? TaxonomyMapper.defaultKnowledgeTypes
            : options,
      );
    });
  }

  @override
  Future<Result<List<TaxonomyOption>>> fetchGamelanTypes() async {
    return _run((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.gamelanTypes,
        token: token,
      );
      final options = TaxonomyMapper.optionsFromApiList(response.data);
      return Success(
        options.isEmpty ? TaxonomyMapper.defaultGamelanTypes : options,
      );
    });
  }

  List<KnowledgeItem> _searchResultsFromApi(Object? data) {
    final entries = asObjectMapList(data);
    final items = <KnowledgeItem>[];
    for (final entry in entries) {
      final knowledgeMap =
          nestedObject(entry, const ['knowledge_item']) ?? entry;
      final item = KnowledgeItem.fromApi(
        knowledgeMap,
        taxonomy: _taxonomyMapper,
      );
      if (item != null) {
        items.add(item);
      }
    }
    if (items.isNotEmpty) {
      return items;
    }
    return KnowledgeItem.listFromApi(data, taxonomy: _taxonomyMapper);
  }

  Future<Result<T>> _run<T>(
    Future<Result<T>> Function(String? token) action,
  ) async {
    final token = await _tokenResolver?.call();
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
