import '../../contributions/data/contribution_model.dart';
import '../../contributions/data/remote_contribution_repository.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/repository_errors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/mapping/taxonomy_mapper.dart';
import '../../../core/utils/result.dart';
import 'review_repository.dart';

class RemoteReviewRepository implements ReviewRepository {
  RemoteReviewRepository({
    required ApiClient apiClient,
    required TokenResolver tokenResolver,
    TaxonomyMapper? taxonomyMapper,
  }) : _apiClient = apiClient,
       _tokenResolver = tokenResolver,
       _taxonomyMapper = taxonomyMapper ?? TaxonomyMapper();

  final ApiClient _apiClient;
  final TokenResolver _tokenResolver;
  final TaxonomyMapper _taxonomyMapper;

  @override
  Future<Result<List<ContributionModel>>> fetchReviewQueue() async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.reviewQueue,
        token: token,
      );
      final queue = ContributionModel.listFromApi(
        response.data,
        taxonomy: _taxonomyMapper,
      );
      return Success(queue);
    });
  }

  @override
  Future<Result<void>> approveContribution(
    String contributionId,
    String note,
  ) async {
    return _postDecision(
      ApiEndpoints.reviewApprove(contributionId),
      note: note,
    );
  }

  @override
  Future<Result<void>> rejectContribution(
    String contributionId,
    String note,
  ) async {
    return _postDecision(
      ApiEndpoints.reviewReject(contributionId),
      note: note,
    );
  }

  @override
  Future<Result<void>> requestChanges(
    String contributionId,
    String note,
  ) async {
    return _postDecision(
      ApiEndpoints.reviewRequestRevision(contributionId),
      note: note,
    );
  }

  Future<Result<void>> _postDecision(
    String path, {
    required String note,
  }) async {
    return _runAuthenticated((token) async {
      await _apiClient.postJson(
        path,
        token: token,
        body: {'note': note.trim()},
      );
      return const Success(null);
    });
  }

  Future<Result<T>> _runAuthenticated<T>(
    Future<Result<T>> Function(String token) action,
  ) async {
    final token = await _tokenResolver();
    if (token == null || token.isEmpty) {
      return const Failure('Please sign in to continue.');
    }

    try {
      return await action(token);
    } on ApiException catch (exception) {
      final validation = validationExceptionFrom(exception);
      if (validation != null) {
        return Failure(validation.message, exception: validation);
      }
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
