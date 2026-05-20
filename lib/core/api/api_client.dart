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

  Uri endpoint(String path) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBase$normalizedPath');
  }

  Future<ApiResponse> getJson(String path, {String? token}) async {
    final response = await _httpClient.get(
      endpoint(path),
      headers: authInterceptor.jsonHeaders(token: token),
    );
    return _parseResponse(response);
  }

  Future<ApiResponse> postJson(
    String path, {
    Map<String, Object?> body = const {},
    String? token,
  }) async {
    final response = await _httpClient.post(
      endpoint(path),
      headers: authInterceptor.jsonHeaders(token: token),
      body: jsonEncode(body),
    );
    return _parseResponse(response);
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
  });

  final bool success;
  final String message;
  final Object? data;
  final Object? errors;

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

  @override
  String toString() => 'ApiException($statusCode): $message';
}
