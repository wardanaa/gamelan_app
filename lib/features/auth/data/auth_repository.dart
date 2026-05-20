import '../../../core/api/api_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/result.dart';
import 'auth_session.dart';

class AuthRepository {
  const AuthRepository({
    required ApiClient apiClient,
    required TokenStorage tokenStorage,
  }) : _apiClient = apiClient,
       _tokenStorage = tokenStorage;

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  Future<Result<AuthSession>> restoreSession() async {
    final token = await _tokenStorage.readToken();
    if (token == null || token.isEmpty) {
      return const Failure('No saved authentication session.');
    }

    return Success(AuthSession(accessToken: token));
  }

  Future<Result<AuthSession>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.postJson(
        ApiEndpoints.authLogin,
        body: {'email': email.trim(), 'password': password},
      );
      final data = response.dataMap;
      final token = data['access_token'] as String?;
      if (token == null || token.isEmpty) {
        return const Failure('Login response did not include an access token.');
      }

      await _tokenStorage.saveToken(token);
      return Success(
        AuthSession(
          accessToken: token,
          email: _stringFrom(data, const ['email', 'user_email']),
          displayName: _displayNameFrom(data),
        ),
      );
    } on ApiException catch (exception) {
      return Failure(_authMessageFor(exception), exception: exception);
    } on FormatException catch (exception) {
      return Failure(
        'The server returned an invalid authentication response.',
        exception: exception,
      );
    } on Object catch (exception) {
      return Failure(
        'Unable to reach the authentication server.',
        exception: exception,
      );
    }
  }

  Future<Result<void>> signOut() async {
    Failure<void>? logoutFailure;
    final token = await _tokenStorage.readToken();

    if (token != null && token.isNotEmpty) {
      try {
        await _apiClient.postJson(ApiEndpoints.authLogout, token: token);
      } on ApiException catch (exception) {
        logoutFailure = Failure(
          'Signed out locally, but backend logout could not be confirmed.',
          exception: exception,
        );
      } on Object catch (exception) {
        logoutFailure = Failure(
          'Signed out locally, but backend logout could not be confirmed.',
          exception: exception,
        );
      }
    }

    await _tokenStorage.clearToken();
    return logoutFailure ?? const Success(null);
  }

  static String? _displayNameFrom(Map<String, Object?> data) {
    final directName = _stringFrom(data, const ['name', 'display_name']);
    if (directName != null) {
      return directName;
    }

    final user = data['user'];
    if (user is Map<String, Object?>) {
      return _stringFrom(user, const ['name', 'display_name']);
    }
    if (user is Map) {
      final normalizedUser = user.map((key, value) => MapEntry('$key', value));
      return _stringFrom(normalizedUser, const ['name', 'display_name']);
    }
    return null;
  }

  static String? _stringFrom(Map<String, Object?> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    final user = data['user'];
    if (user is Map<String, Object?>) {
      return _stringFrom(user, keys);
    }
    if (user is Map) {
      return _stringFrom(
        user.map((key, value) => MapEntry('$key', value)),
        keys,
      );
    }
    return null;
  }

  static String _authMessageFor(ApiException exception) {
    return switch (exception.statusCode) {
      401 => 'The email or password is incorrect.',
      403 => 'This account is not allowed to access the mobile app.',
      422 => exception.message,
      429 => 'Too many login attempts. Please try again later.',
      >= 500 => 'The authentication server could not complete the request.',
      _ => exception.message,
    };
  }
}
