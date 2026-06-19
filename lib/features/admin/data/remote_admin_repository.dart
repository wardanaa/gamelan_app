import '../../../core/api/api_client.dart';
import '../../../core/api/api_parsers.dart';
import '../../../core/api/repository_errors.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../../contributions/data/remote_contribution_repository.dart';
import 'admin_repository.dart';
import 'admin_user_summary.dart';
import 'audit_log_entry.dart';

class RemoteAdminRepository implements AdminRepository {
  RemoteAdminRepository({
    required ApiClient apiClient,
    required TokenResolver tokenResolver,
  }) : _apiClient = apiClient,
       _tokenResolver = tokenResolver;

  final ApiClient _apiClient;
  final TokenResolver _tokenResolver;

  @override
  Future<Result<List<AdminUserSummary>>> fetchUsers() async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.users,
        token: token,
      );
      final listData = _extractList(response.data, const ['users']);
      if (listData == null) {
        return const Failure('The server returned an invalid admin user list.');
      }
      return Success(AdminUserSummary.listFromApi(listData));
    });
  }

  @override
  Future<Result<List<AuditLogEntry>>> fetchAuditLogs() async {
    return _runAuthenticated((token) async {
      final response = await _apiClient.getJson(
        ApiEndpoints.auditLogs,
        token: token,
      );
      final listData = _extractList(response.data, const [
        'audit_logs',
        'auditLogs',
        'logs',
      ]);
      if (listData == null) {
        return const Failure('The server returned an invalid audit log list.');
      }
      return Success(AuditLogEntry.listFromApi(listData));
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

Object? _extractList(Object? data, List<String> listKeys) {
  if (data is Iterable) {
    return data;
  }

  final map = asObjectMap(data);
  if (map.isEmpty) {
    return null;
  }

  for (final key in listKeys) {
    final value = map[key];
    if (value is Iterable) {
      return value;
    }
  }

  final nestedData = map['data'];
  if (nestedData is Iterable) {
    return nestedData;
  }

  final nestedMap = asObjectMap(nestedData);
  if (nestedMap.isEmpty) {
    return null;
  }
  for (final key in listKeys) {
    final value = nestedMap[key];
    if (value is Iterable) {
      return value;
    }
  }

  return null;
}
