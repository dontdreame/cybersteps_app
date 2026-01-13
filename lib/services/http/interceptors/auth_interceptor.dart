import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../auth/token_storage.dart';

/// Injects Authorization header from flutter_secure_storage.
class AuthInterceptor extends Interceptor {
  AuthInterceptor();

  static final TokenStorage _tokenStorage =
      TokenStorage(const FlutterSecureStorage());

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _tokenStorage.readToken();
      if (token != null && token.trim().isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {
      // ignore storage errors
    }
    handler.next(options);
  }
}
