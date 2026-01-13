import 'package:dio/dio.dart';

import '../http/api_utils.dart';

class QuizApi {
  QuizApi(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> listByLevel(int levelId) async {
    final res = await _dio.get(ApiUtils.apiPath(_dio, 'quizzes/level/$levelId'));
    final data = ApiUtils.unwrap(res.data);
    if (data is List) {
      return data.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    return const [];
  }

  Future<Map<String, dynamic>> getQuiz(int quizId) async {
    final res = await _dio.get(ApiUtils.apiPath(_dio, 'quizzes/$quizId'));
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }

  Future<Map<String, dynamic>> submit({
    required int quizId,
    required List<Map<String, dynamic>> answers,
  }) async {
    final res = await _dio.post(
      ApiUtils.apiPath(_dio, 'quizzes/submit'),
      data: {
        'quizId': quizId,
        'answers': answers,
      },
    );
    final data = ApiUtils.unwrap(res.data);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return data.cast<String, dynamic>();
    return {'raw': data};
  }
}
