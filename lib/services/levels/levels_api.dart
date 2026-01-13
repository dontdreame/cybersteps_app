import 'package:dio/dio.dart';

import '../../models/level.dart';

class LevelsOverviewResponse {
  LevelsOverviewResponse({
    required this.currentLevelId,
    required this.currentLevelOrder,
    required this.levels,
    required this.nextUnlockStatus,
  });

  final int? currentLevelId;
  final int currentLevelOrder;
  final List<Level> levels;

  /// Raw backend object from GET /api/levels/unlock-status or /api/levels/overview
  final Map<String, dynamic> nextUnlockStatus;

  factory LevelsOverviewResponse.fromApiResponse(Map<String, dynamic> raw) {
    // unwrap {success,data} if present
    final data = (raw['data'] is Map<String, dynamic>) ? (raw['data'] as Map<String, dynamic>) : raw;

    int parseInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final currentLevelId = data['currentLevelId'] == null ? null : parseInt(data['currentLevelId'], fallback: 0);
    final currentLevelOrder = parseInt(data['currentLevelOrder'], fallback: 0);

    final levelsRaw = (data['levels'] is List) ? (data['levels'] as List) : const [];
    final levels = levelsRaw
        .whereType<Map>()
        .map((e) => Level.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final nextUnlockStatus = (data['nextUnlockStatus'] is Map<String, dynamic>)
        ? (data['nextUnlockStatus'] as Map<String, dynamic>)
        : <String, dynamic>{};

    return LevelsOverviewResponse(
      currentLevelId: currentLevelId == 0 ? null : currentLevelId,
      currentLevelOrder: currentLevelOrder,
      levels: levels,
      nextUnlockStatus: nextUnlockStatus,
    );
  }
}

class LevelDetailResponse {
  LevelDetailResponse({
    required this.level,
    required this.exams,
    required this.quizzes,
    required this.studyPlanTemplate,
  });

  final Level level;
  final List<Map<String, dynamic>> exams;
  final List<Map<String, dynamic>> quizzes;

  /// Can be null if no template exists.
  final Map<String, dynamic>? studyPlanTemplate;

  factory LevelDetailResponse.fromApiResponse(Map<String, dynamic> raw) {
    final data = (raw['data'] is Map<String, dynamic>) ? (raw['data'] as Map<String, dynamic>) : raw;

    final levelRaw = (data['level'] is Map<String, dynamic>) ? (data['level'] as Map<String, dynamic>) : <String, dynamic>{};
    final level = Level.fromJson(levelRaw);

    List<Map<String, dynamic>> listOfMaps(dynamic v) {
      if (v is! List) return <Map<String, dynamic>>[];
      return v
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }

    final exams = listOfMaps(data['exams']);
    final quizzes = listOfMaps(data['quizzes']);

    final tpl = (data['studyPlanTemplate'] is Map<String, dynamic>)
        ? (data['studyPlanTemplate'] as Map<String, dynamic>)
        : null;

    return LevelDetailResponse(level: level, exams: exams, quizzes: quizzes, studyPlanTemplate: tpl);
  }
}

class LevelsApi {
  LevelsApi(this._dio);

  final Dio _dio;

  String _apiPath(String relative) {
    final base = _dio.options.baseUrl;
    final hasApi = base.contains('/api') || base.endsWith('/api');
    if (hasApi) return relative.startsWith('/') ? relative : '/$relative';
    return relative.startsWith('/api') ? relative : '/api$relative';
  }

  Future<LevelsOverviewResponse> fetchOverview() async {
    final r = await _dio.get(_apiPath('/levels/overview'));
    return LevelsOverviewResponse.fromApiResponse(Map<String, dynamic>.from(r.data as Map));
  }

  Future<LevelDetailResponse> fetchLevelDetail(int levelId) async {
    final r = await _dio.get(_apiPath('/levels/$levelId/overview'));
    return LevelDetailResponse.fromApiResponse(Map<String, dynamic>.from(r.data as Map));
  }
}
