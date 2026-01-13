import 'package:dio/dio.dart';

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// Builds an endpoint path that works whether your Dio baseUrl is:
  /// - https://<host>          (NO /api)
  /// - https://<host>/api      (HAS /api)
  ///
  /// We will avoid double /api/api.
  String _apiPath(String relative) {
    final base = _dio.options.baseUrl;
    final hasApiInBase = base.contains('/api');
    final cleaned = relative.startsWith('/') ? relative.substring(1) : relative;

    if (hasApiInBase) return '/$cleaned';
    return '/api/$cleaned';
  }

  Future<Map<String, dynamic>> fetchMe({String? token}) async {
    try {
      final res = await _dio.get(
        _apiPath('students/me'),
        options: (token != null && token.trim().isNotEmpty)
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );

      if (res.data is Map<String, dynamic>) return res.data as Map<String, dynamic>;
      return {'raw': res.data};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('fetchMe failed (status=$status) data=$data');
    }
  }

  Future<String> loginWithFirebaseIdToken(String idToken) async {
    try {
      final res = await _dio.post(
        _apiPath('auth/firebase-login'),
        data: {'idToken': idToken},
      );

      final token = _extractTokenFlexible(res.data);
      if (token != null && token.isNotEmpty) return token;

      // Helpful debug when token not found
      final keys = _keysPreview(res.data);
      throw Exception(
        'Token not found in /auth/firebase-login response. Top-level keys: $keys, data=${res.data}',
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;
      throw Exception('firebase-login failed (status=$status) data=$data');
    }
  }

  String _keysPreview(dynamic data) {
    if (data is Map) return data.keys.toList().toString();
    return data.runtimeType.toString();
  }

  /// Supports common response shapes:
  /// 1) { token: "..." }
  /// 2) { accessToken: "..." }
  /// 3) { data: { token: "..." } }
  /// 4) { data: { accessToken: "..." } }
  /// 5) { success: true, data: { student: {...}, token: "..." } }
  /// 6) { data: { data: { token: "..." } } }  (nested wrappers)
  String? _extractTokenFlexible(dynamic data) {
    const tokenKeys = ['token', 'accessToken', 'jwt'];

    String? fromMap(Map<String, dynamic> m) {
      for (final k in tokenKeys) {
        final v = m[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return null;
    }

    if (data is Map<String, dynamic>) {
      // top-level
      final direct = fromMap(data);
      if (direct != null) return direct;

      // common wrapper: data
      final inner = data['data'];
      if (inner is Map<String, dynamic>) {
        final t = fromMap(inner);
        if (t != null) return t;

        // nested data wrapper
        final inner2 = inner['data'];
        if (inner2 is Map<String, dynamic>) {
          final t2 = fromMap(inner2);
          if (t2 != null) return t2;
        }
      }
    }

    return null;
  }
}
