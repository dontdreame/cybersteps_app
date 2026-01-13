import 'package:dio/dio.dart';

import '../http/api_utils.dart';

class ExamApi {
  ExamApi(this._dio);

  final Dio _dio;

  /// Starts the (final) exam.
  /// Backend uses student's level from token.
  Future<Map<String, dynamic>> start({int? levelId}) async {
    final res = await _dio.post(
      ApiUtils.apiPath(_dio, 'exams/start'),
      data: levelId != null ? {'levelId': levelId} : null,
    );
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }

  Future<Map<String, dynamic>> submit({
    required int examId,
    required String examSessionToken,
    required List<Map<String, dynamic>> answers,
  }) async {
    final res = await _dio.post(
      ApiUtils.apiPath(_dio, 'exams/submit'),
      data: {
        'examId': examId,
        'examSessionToken': examSessionToken,
        'answers': answers,
      },
    );
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }
}
