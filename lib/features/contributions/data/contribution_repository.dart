import '../../../core/api/api_client.dart';
import '../../../core/utils/result.dart';
import 'contribution_model.dart';

class ContributionRepository {
  const ContributionRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<Result<List<ContributionModel>>> fetchContributions() async {
    _apiClient.endpoint('/contributions');
    return const Success([]);
  }
}
