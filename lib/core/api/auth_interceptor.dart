class AuthInterceptor {
  const AuthInterceptor();

  Map<String, String> jsonHeaders({String? token}) {
    return attachToken(const {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    }, token: token);
  }

  Map<String, String> attachToken(
    Map<String, String> headers, {
    String? token,
  }) {
    if (token == null || token.isEmpty) {
      return headers;
    }

    return {...headers, 'Authorization': 'Bearer $token'};
  }
}
