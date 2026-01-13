import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _kTokenKey = 'auth_token';

  Future<void> saveToken(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _kTokenKey);

  Future<void> clearToken() => _storage.delete(key: _kTokenKey);
}
