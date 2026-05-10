import 'auth_interceptor.dart';

class ApiClient {
  ApiClient({required this.baseUrl, AuthInterceptor? authInterceptor})
    : authInterceptor = authInterceptor ?? AuthInterceptor();

  final String baseUrl;
  final AuthInterceptor authInterceptor;

  Uri endpoint(String path) {
    return Uri.parse('$baseUrl$path');
  }
}
