import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/result.dart';

class AuthRepository {
  const AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    _apiClient.endpoint('/auth/login');
    await _tokenStorage.saveToken('placeholder-token');
    return const Success(null);
  }

  Future<void> signOut() {
    return _tokenStorage.clearToken();
  }
}
