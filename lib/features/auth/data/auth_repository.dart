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

    final profileResult = await loadProfile(token);
    switch (profileResult) {
      case Success<AuthSession>(:final value):
        if (value.isExpired) {
          await _tokenStorage.clearToken();
          return const Failure('Saved session has expired.');
        }
        return Success(value);
      case Failure<AuthSession>(:final message, :final exception):
        if (_shouldClearToken(exception)) {
          await _tokenStorage.clearToken();
        }
        return Failure(message, exception: exception);
    }
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
      return _sessionFromTokenResponse(response.dataMap);
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

  Future<Result<AuthSession>> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await _apiClient.postJson(
        ApiEndpoints.authRegister,
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
          'password_confirmation': passwordConfirmation,
        },
      );
      return _sessionFromTokenResponse(response.dataMap);
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

  Future<Result<AuthSession>> loadProfile(String token) async {
    try {
      final response = await _apiClient.getJson(ApiEndpoints.me, token: token);
      return Success(_sessionFromProfile(token: token, data: response.dataMap));
    } on ApiException catch (exception) {
      return Failure(_profileMessageFor(exception), exception: exception);
    } on FormatException catch (exception) {
      return Failure(
        'The server returned an invalid profile response.',
        exception: exception,
      );
    } on Object catch (exception) {
      return Failure(
        'Unable to load the authenticated profile.',
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

  Future<Result<AuthSession>> _sessionFromTokenResponse(
    Map<String, Object?> data,
  ) async {
    final token = _stringFrom(data, const ['access_token']);
    if (token == null || token.isEmpty) {
      return const Failure('Authentication response did not include a token.');
    }

    final profileResult = await loadProfile(token);
    switch (profileResult) {
      case Success<AuthSession>(:final value):
        final session = AuthSession(
          accessToken: token,
          email: value.email,
          displayName: value.displayName,
          roles: value.roles,
          permissions: value.permissions,
          tokenExpiresAt: value.tokenExpiresAt ?? _tokenExpiresAtFrom(data),
        );
        if (session.isExpired) {
          await _tokenStorage.clearToken();
          return const Failure('The issued authentication token has expired.');
        }
        await _tokenStorage.saveToken(token);
        return Success(session);
      case Failure<AuthSession>(:final message, :final exception):
        await _tokenStorage.clearToken();
        return Failure(message, exception: exception);
    }
  }

  AuthSession _sessionFromProfile({
    required String token,
    required Map<String, Object?> data,
  }) {
    final user = _userMapFrom(data);
    final source = user ?? data;
    final sourceRoles = _stringsFrom(source, const ['roles']);
    final sourcePermissions = _stringsFrom(source, const ['permissions']);
    return AuthSession(
      accessToken: token,
      email: _stringFrom(source, const ['email', 'user_email']),
      displayName: _displayNameFrom(source),
      roles: sourceRoles.isNotEmpty
          ? sourceRoles
          : _stringsFrom(data, const ['roles']),
      permissions: sourcePermissions.isNotEmpty
          ? sourcePermissions
          : _stringsFrom(data, const ['permissions']),
      tokenExpiresAt: _tokenExpiresAtFrom(data) ?? _tokenExpiresAtFrom(source),
    );
  }

  static bool _shouldClearToken(Object? exception) {
    return exception is ApiException && exception.statusCode == 401;
  }

  static Map<String, Object?>? _userMapFrom(Map<String, Object?> data) {
    final user = data['user'];
    if (user is Map<String, Object?>) {
      return user;
    }
    if (user is Map) {
      return user.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  static DateTime? _tokenExpiresAtFrom(Map<String, Object?> data) {
    final value = _stringFrom(data, const [
      'token_expires_at',
      'expires_at',
      'access_token_expires_at',
    ]);
    if (value == null) {
      return null;
    }

    return DateTime.tryParse(value);
  }

  static List<String> _stringsFrom(
    Map<String, Object?> data,
    List<String> keys,
  ) {
    for (final key in keys) {
      final strings = _normalizeStrings(data[key]);
      if (strings.isNotEmpty) {
        return strings;
      }
    }

    final user = _userMapFrom(data);
    if (user != null) {
      return _stringsFrom(user, keys);
    }

    return const [];
  }

  static List<String> _normalizeStrings(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return [_normalizeSlug(value)];
    }
    if (value is Iterable) {
      return value
          .map((entry) {
            if (entry is String) {
              return entry;
            }
            if (entry is Map<String, Object?>) {
              return _stringFrom(entry, const ['name', 'slug', 'key']);
            }
            if (entry is Map) {
              return _stringFrom(
                entry.map((key, value) => MapEntry('$key', value)),
                const ['name', 'slug', 'key'],
              );
            }
            return null;
          })
          .whereType<String>()
          .map(_normalizeSlug)
          .where((entry) => entry.isNotEmpty)
          .toSet()
          .toList(growable: false);
    }

    return const [];
  }

  static String _normalizeSlug(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  }

  static String? _displayNameFrom(Map<String, Object?> data) {
    final directName = _stringFrom(data, const ['name', 'display_name']);
    if (directName != null) {
      return directName;
    }

    final user = _userMapFrom(data);
    if (user != null) {
      return _stringFrom(user, const ['name', 'display_name']);
    }
    return null;
  }

  static String? _stringFrom(Map<String, Object?> data, List<String> keys) {
    for (final key in keys) {
      final value = data[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }

    final user = _userMapFrom(data);
    if (user != null) {
      return _stringFrom(user, keys);
    }
    return null;
  }

  static String _authMessageFor(ApiException exception) {
    return switch (exception.statusCode) {
      401 => 'The email or password is incorrect.',
      403 => 'This account is not allowed to access the mobile app.',
      422 => exception.message,
      429 => 'Too many authentication attempts. Please try again later.',
      >= 500 => 'The authentication server could not complete the request.',
      _ => exception.message,
    };
  }

  static String _profileMessageFor(ApiException exception) {
    return switch (exception.statusCode) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'This account is not allowed to access the mobile app.',
      429 => 'Too many profile requests. Please try again later.',
      >= 500 => 'The profile server could not complete the request.',
      _ => exception.message,
    };
  }
}
