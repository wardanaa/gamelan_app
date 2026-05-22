import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({
    required this.baseUrl,
    AuthInterceptor? authInterceptor,
    http.Client? httpClient,
  }) : authInterceptor = authInterceptor ?? const AuthInterceptor(),
       _httpClient = httpClient ?? http.Client();

  factory ApiClient.fromEnvironment({http.Client? httpClient}) {
    return ApiClient(baseUrl: defaultBaseUrl, httpClient: httpClient);
  }

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final String baseUrl;
  final AuthInterceptor authInterceptor;
  final http.Client _httpClient;

  Uri endpoint(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final uri = Uri.parse('$normalizedBase$normalizedPath');
    if (queryParameters == null || queryParameters.isEmpty) {
      return uri;
    }
    return uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      },
    );
  }

  Future<ApiResponse> getJson(
    String path, {
    String? token,
    Map<String, String>? queryParameters,
  }) async {
    final response = await _httpClient.get(
      endpoint(path, queryParameters: queryParameters),
      headers: authInterceptor.jsonHeaders(token: token),
    );
    return _parseResponse(response);
  }

  Future<ApiResponse> postJson(
    String path, {
    Map<String, Object?> body = const {},
    String? token,
    String? idempotencyKey,
  }) async {
    final response = await _httpClient.post(
      endpoint(path),
      headers: _writeHeaders(token: token, idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<ApiResponse> putJson(
    String path, {
    Map<String, Object?> body = const {},
    String? token,
    String? idempotencyKey,
  }) async {
    final response = await _httpClient.put(
      endpoint(path),
      headers: _writeHeaders(token: token, idempotencyKey: idempotencyKey),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
  }

  Future<ApiResponse> deleteJson(
    String path, {
    String? token,
    String? idempotencyKey,
  }) async {
    final response = await _httpClient.delete(
      endpoint(path),
      headers: _writeHeaders(token: token, idempotencyKey: idempotencyKey),
    );
    return _parseResponse(response);
  }

  Map<String, String> _writeHeaders({
    String? token,
    String? idempotencyKey,
  }) {
    final headers = authInterceptor.jsonHeaders(token: token);
    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      return {...headers, 'Idempotency-Key': idempotencyKey};
    }
    return headers;
  }

  ApiResponse _parseResponse(http.Response response) {
    final decodedBody = _decodeResponseBody(response.body);
    final message = decodedBody['message'] as String?;
    final success = decodedBody['success'];

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        statusCode: response.statusCode,
        message: message ?? _defaultErrorMessage(response.statusCode),
        errors: decodedBody['errors'],
      );
    }

    if (success == false) {
      throw ApiException(
        statusCode: response.statusCode,
        message: message ?? 'The request could not be completed.',
        errors: decodedBody['errors'],
      );
    }

    return ApiResponse(
      success: success == true,
      message: message ?? 'Request completed successfully.',
      data: decodedBody['data'],
      errors: decodedBody['errors'],
      meta: decodedBody['meta'],
    );
  }

  Map<String, Object?> _decodeResponseBody(String body) {
    if (body.trim().isEmpty) {
      return const {};
    }

    final decoded = jsonDecode(body);
    if (decoded is Map<String, Object?>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry('$key', value));
    }

    throw const FormatException('API response body must be a JSON object.');
  }

  String _defaultErrorMessage(int statusCode) {
    return switch (statusCode) {
      401 => 'Please sign in again.',
      403 => 'You do not have permission to perform this action.',
      404 => 'The requested resource was not found.',
      409 => 'This record changed on the server. Please refresh and try again.',
      422 => 'Please check the submitted information.',
      429 => 'Too many requests. Please try again later.',
      >= 500 => 'The server could not complete the request.',
      _ => 'The request could not be completed.',
    };
  }
}

class ApiResponse {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.meta,
  });

  final bool success;
  final String message;
  final Object? data;
  final Object? errors;
  final Object? meta;

  Map<String, Object?> get dataMap {
    final responseData = data;
    if (responseData is Map<String, Object?>) {
      return responseData;
    }
    if (responseData is Map) {
      return responseData.map((key, value) => MapEntry('$key', value));
    }
    return const {};
  }

  ApiPaginationMeta? get paginationMeta {
    final metaValue = meta;
    if (metaValue is Map<String, Object?>) {
      return ApiPaginationMeta.fromMap(metaValue);
    }
    if (metaValue is Map) {
      return ApiPaginationMeta.fromMap(
        metaValue.map((key, value) => MapEntry('$key', value)),
      );
    }
    return null;
  }
}

class ApiPaginationMeta {
  const ApiPaginationMeta({
    required this.currentPage,
    required this.perPage,
    required this.total,
  });

  final int currentPage;
  final int perPage;
  final int total;

  static ApiPaginationMeta? fromMap(Map<String, Object?> map) {
    final currentPage = _intFrom(map['current_page']);
    final perPage = _intFrom(map['per_page']);
    final total = _intFrom(map['total']);
    if (currentPage == null || perPage == null || total == null) {
      return null;
    }
    return ApiPaginationMeta(
      currentPage: currentPage,
      perPage: perPage,
      total: total,
    );
  }

  static int? _intFrom(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.errors,
  });

  final int statusCode;
  final String message;
  final Object? errors;

  Map<String, List<String>> get fieldErrors {
    final errorsValue = errors;
    if (errorsValue is! Map) {
      return const {};
    }

    final mapped = <String, List<String>>{};
    for (final entry in errorsValue.entries) {
      final messages = _normalizeErrorMessages(entry.value);
      if (messages.isNotEmpty) {
        mapped['${entry.key}'] = messages;
      }
    }
    return mapped;
  }

  static List<String> _normalizeErrorMessages(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    if (value is Iterable) {
      return value
          .map((entry) => entry?.toString().trim())
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }
    return const [];
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
