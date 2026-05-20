import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorageBackend {
  Future<void> write({required String key, required String value});

  Future<String?> read({required String key});

  Future<void> delete({required String key});
}

class FlutterSecureTokenStorageBackend implements TokenStorageBackend {
  const FlutterSecureTokenStorageBackend({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
  }) : _secureStorage = secureStorage;

  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> write({required String key, required String value}) {
    return _secureStorage.write(key: key, value: value);
  }

  @override
  Future<String?> read({required String key}) {
    return _secureStorage.read(key: key);
  }

  @override
  Future<void> delete({required String key}) {
    return _secureStorage.delete(key: key);
  }
}

class TokenStorage {
  const TokenStorage({
    TokenStorageBackend backend = const FlutterSecureTokenStorageBackend(),
  }) : _backend = backend;

  static const accessTokenKey = 'gamelan_access_token_v1';

  final TokenStorageBackend _backend;

  Future<void> saveToken(String token) async {
    await _backend.write(key: accessTokenKey, value: token);
  }

  Future<String?> readToken() async {
    return _backend.read(key: accessTokenKey);
  }

  Future<void> clearToken() async {
    await _backend.delete(key: accessTokenKey);
  }
}
