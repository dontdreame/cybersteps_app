import 'package:dio/dio.dart';

/// Small helpers shared across APIs.
class ApiUtils {
  /// Builds an endpoint path that works whether Dio baseUrl is:
  /// - https://<host>          (NO /api)
  /// - https://<host>/api      (HAS /api)
  static String apiPath(Dio dio, String relative) {
    final base = dio.options.baseUrl;
    final hasApiInBase = base.contains('/api');
    final cleaned = relative.startsWith('/') ? relative.substring(1) : relative;
    if (hasApiInBase) return '/$cleaned';
    return '/api/$cleaned';
  }

  /// Unwraps common backend wrappers:
  /// - { success: true, data: X }
  /// - { data: X }
  static dynamic unwrap(dynamic raw) {
    dynamic data = raw;
    if (data is Map) {
      if (data.containsKey('data')) data = data['data'];
    }
    if (data is Map && data.containsKey('data')) {
      // Some APIs wrap twice.
      data = data['data'];
    }
    return data;
  }

  /// Human-friendly Arabic error message.
  static String humanizeDioError(Object err) {
    if (err is DioException) {
      if (err.type == DioExceptionType.connectionTimeout ||
          err.type == DioExceptionType.receiveTimeout ||
          err.type == DioExceptionType.sendTimeout) {
        return 'انتهت مهلة الاتصال. جرّب مرة ثانية.';
      }

      final status = err.response?.statusCode;
      final data = err.response?.data;

      // Try common backend message fields.
      String? msg;
      if (data is Map) {
        final m1 = data['message'];
        final m2 = data['error'];
        if (m1 is String && m1.trim().isNotEmpty) msg = m1.trim();
        if (msg == null && m2 is String && m2.trim().isNotEmpty) msg = m2.trim();
      }

      if (status == 401) return 'غير مصرح. سجّل دخولك مرة ثانية.';
      if (status == 403) return 'ممنوع الوصول.';
      if (status == 404) return msg ?? 'غير موجود.';
      if (status == 409) return msg ?? 'في تعارض/محاولة مكررة.';
      if (status != null) return msg ?? 'صار خطأ بالسيرفر (status=$status).';

      return 'تعذّر الاتصال بالسيرفر.';
    }

    return 'صار خطأ غير متوقع.';
  }
}
