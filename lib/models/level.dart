import 'dart:convert';

/// A learning level (Level 0..5).
///
/// Patch 3 notes:
/// - We support backend-driven status when present (status/lockedReason).
/// - Otherwise, we compute status on the client using student's currentLevel.
class Level {
  const Level({
    required this.id,
    required this.order,
    required this.title,
    this.description,
    this.status, // optional (backend-driven)
    this.lockedReason, // optional (backend-driven)
  });

  final int id;
  final int order;
  final String title;
  final String? description;

  /// Optional backend-driven status: 'LOCKED' | 'AVAILABLE' | 'COMPLETED'
  final String? status;

  /// Optional backend-driven reason string (Arabic preferred).
  final String? lockedReason;

  bool get hasBackendStatus => status != null && status!.trim().isNotEmpty;

  /// Flexible parser: accepts a raw map, or wrapper shapes like:
  /// - { success: true, data: [...] }
  /// - { data: [...] }
  static List<Level> listFromApiResponse(dynamic raw) {
    dynamic data = raw;
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner != null) data = inner;
    }
    if (data is List) {
      return data.whereType<Map>().map((m) => Level.fromJson(Map<String, dynamic>.from(m))).toList();
    }
    return const <Level>[];
  }

  factory Level.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final id = parseInt(json['id'], fallback: parseInt(json['levelId'], fallback: 0));
    final order = parseInt(json['order'], fallback: parseInt(json['index'], fallback: id));

    return Level(
      id: id,
      order: order,
      title: (json['title'] ?? json['name'] ?? 'Level $order').toString(),
      description: json['description']?.toString(),
      status: json['status']?.toString(),
      lockedReason: json['lockedReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'order': order,
        'title': title,
        'description': description,
        'status': status,
        'lockedReason': lockedReason,
      };

  @override
  String toString() => jsonEncode(toJson());

  /// Fallback static catalog (works even if backend endpoints are not ready yet).
  static List<Level> staticCatalog() => const [
        Level(id: 0, order: 0, title: 'Level 0 — الأساسيات', description: 'Networking + Linux + أساسيات السايبر'),
        Level(id: 1, order: 1, title: 'Level 1 — Foundations', description: 'Linux/Windows basics + CLI + Labs'),
        Level(id: 2, order: 2, title: 'Level 2 — Intermediate', description: 'Blue-team workflows + monitoring'),
        Level(id: 3, order: 3, title: 'Level 3 — Advanced', description: 'Threat hunting + hardening'),
        Level(id: 4, order: 4, title: 'Level 4 — Track', description: 'Blue/Red/GRC/DevSecOps tracks'),
        Level(id: 5, order: 5, title: 'Level 5 — Mastery', description: 'Capstone + final assessment'),
      ];
}

enum LevelUiStatus { locked, available, completed }

LevelUiStatus computeLevelStatus({
  required Level level,
  required int currentLevel,
}) {
  // If backend provides status, use it.
  final s = level.status?.toUpperCase().trim();
  if (s == 'COMPLETED') return LevelUiStatus.completed;
  if (s == 'AVAILABLE' || s == 'UNLOCKED' || s == 'OPEN') return LevelUiStatus.available;
  if (s == 'LOCKED' || s == 'CLOSED') return LevelUiStatus.locked;

  // Fallback compute:
  // - completed: below current
  // - available: current
  // - locked: above current
  if (level.order < currentLevel) return LevelUiStatus.completed;
  if (level.order == currentLevel) return LevelUiStatus.available;
  return LevelUiStatus.locked;
}

String defaultLockReason({
  required Level level,
  required int currentLevel,
}) {
  // If backend provides reason, prefer it.
  final r = level.lockedReason;
  if (r != null && r.trim().isNotEmpty) return r;

  if (level.order <= currentLevel) return '';
  final prev = level.order - 1;
  if (prev < 0) return 'هذا المستوى غير متاح الآن.';

  return 'هذا المستوى مقفول. لازم تخلص المستوى $prev (وتنجح بالامتحان النهائي) عشان ينفتح.';
}
