import '../../../core/api/api_client.dart';
import '../../../core/utils/result.dart';
import 'review_model.dart';

class ReviewRepository {
  const ReviewRepository({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<List<ReviewModel>>> fetchReviewQueue() async {
    _apiClient.endpoint('/reviews');
    return const Success([]);
  }
}
