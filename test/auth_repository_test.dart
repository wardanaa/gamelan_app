import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gamelan_app/core/api/api_client.dart';
import 'package:gamelan_app/core/storage/token_storage.dart';
import 'package:gamelan_app/core/utils/result.dart';
import 'package:gamelan_app/features/auth/data/auth_repository.dart';
import 'package:gamelan_app/features/auth/data/auth_session.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('auth repository parses nested /me roles and permissions', () async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/me')) {
        expect(request.headers['authorization'], 'Bearer nested-token');
        return jsonResponse({
          'success': true,
          'message': 'OK',
          'data': {
            'user': {
              'name': 'Curator Reviewer',
              'email': 'curator@example.com',
              'roles': [
                'curator',
                {'slug': 'peer_reviewer'},
              ],
              'permissions': [
                'review.contributions',
                {'name': 'validate.expert'},
              ],
            },
          },
        });
      }
      return jsonResponse({'success': false, 'message': 'Not found'}, 404);
    });

    final repository = AuthRepository(
      apiClient: ApiClient(
        baseUrl: 'http://localhost/api/v1',
        httpClient: client,
      ),
      tokenStorage: TokenStorage(backend: MemoryTokenStorageBackend()),
    );

    final result = await repository.loadProfile('nested-token');
    final session = switch (result) {
      Success<AuthSession>(:final value) => value,
      Failure<AuthSession>(:final message) => fail(message),
    };

    expect(session.displayLabel, 'Curator Reviewer');
    expect(session.roles, ['curator', 'peer_reviewer']);
    expect(session.permissions, ['review.contributions', 'validate.expert']);
    expect(session.roleLabel, 'curator, peer_reviewer');
  });

  test(
    'auth repository parses root /me roles and permissions fallback',
    () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/me')) {
          expect(request.headers['authorization'], 'Bearer root-token');
          return jsonResponse({
            'success': true,
            'message': 'OK',
            'data': {
              'name': 'Expert Validator',
              'email': 'expert@example.com',
              'roles': ['expert_validator'],
              'permissions': ['review.contributions', 'validate.expert'],
            },
          });
        }
        return jsonResponse({'success': false, 'message': 'Not found'}, 404);
      });

      final repository = AuthRepository(
        apiClient: ApiClient(
          baseUrl: 'http://localhost/api/v1',
          httpClient: client,
        ),
        tokenStorage: TokenStorage(backend: MemoryTokenStorageBackend()),
      );

      final result = await repository.loadProfile('root-token');
      final session = switch (result) {
        Success<AuthSession>(:final value) => value,
        Failure<AuthSession>(:final message) => fail(message),
      };

      expect(session.displayLabel, 'Expert Validator');
      expect(session.roles, ['expert_validator']);
      expect(session.permissions, ['review.contributions', 'validate.expert']);
      expect(session.roleLabel, 'expert_validator');
    },
  );
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

http.Response jsonResponse(Map<String, Object?> body, [int statusCode = 200]) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}
