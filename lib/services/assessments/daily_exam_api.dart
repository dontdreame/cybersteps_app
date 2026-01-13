import 'package:dio/dio.dart';

import '../http/api_utils.dart';

class DailyExamApi {
  DailyExamApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getToday() async {
    final res = await _dio.get(ApiUtils.apiPath(_dio, 'daily-exam/today'));
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }

  Future<Map<String, dynamic>> submitToday({
    required List<Map<String, dynamic>> answers,
  }) async {
    final res = await _dio.post(
      ApiUtils.apiPath(_dio, 'daily-exam/submit'),
      data: {'answers': answers},
    );
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }

  Future<Map<String, dynamic>> getResult({String? dateYmd}) async {
    final res = await _dio.get(
      ApiUtils.apiPath(_dio, 'daily-exam/result'),
      queryParameters: dateYmd != null ? {'date': dateYmd} : null,
    );
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }
}
