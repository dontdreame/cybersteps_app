import 'package:dio/dio.dart';

/// Placeholder for auth header injection.
/// Later you'll read token from Riverpod (secure storage) and add:
/// options.headers['Authorization'] = 'Bearer $token';
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // TODO: inject token when auth is ready.
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // TODO: handle 401 global logout if needed.
    handler.next(err);
  }
}
