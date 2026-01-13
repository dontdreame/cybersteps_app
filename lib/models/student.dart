class Student {
  Student({
    required this.id,
    required this.fullName,
    this.username,
    this.email,
    this.levelId,
    this.pendingPoints,
    this.spendablePoints,
    this.totalPoints,
    this.warningCount,
  });

  /// Backend uses Int id; we keep it as String for UI stability.
  final String id;

  final String fullName;
  final String? username;
  final String? email;

  /// Current Level (in backend it's usually `levelId`).
  final int? levelId;

  final int? pendingPoints;
  final int? spendablePoints;
  final int? totalPoints;

  /// Optional: if backend provides a warning count (not always present).
  final int? warningCount;

  int get pointsForDashboard {
    // Prefer spendable, then total, then pending.
    return spendablePoints ?? totalPoints ?? pendingPoints ?? 0;
  }

  static int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static String _asString(dynamic v) => v == null ? '' : '$v';

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    // Accept:
    // 1) { success: true, data: {...student} }
    // 2) { data: {...student} }
    // 3) { ...student }
    final data = raw['data'];
    if (data is Map<String, dynamic>) {
      // Some endpoints wrap twice: { data: { data: {...} } }
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return raw;
  }

  factory Student.fromApiResponse(Map<String, dynamic> raw) {
    final m = _unwrap(raw);

    return Student(
      id: _asString(m['id']),
      fullName: (m['fullName'] is String && (m['fullName'] as String).trim().isNotEmpty)
          ? (m['fullName'] as String).trim()
          : 'طالب',
      username: m['username'] as String?,
      email: m['email'] as String?,
      levelId: _asInt(m['levelId'] ?? m['currentLevel']),
      pendingPoints: _asInt(m['pendingPoints']),
      spendablePoints: _asInt(m['spendablePoints']),
      totalPoints: _asInt(m['totalPoints']),
      warningCount: _asInt(m['warningCount'] ?? m['warningsCount']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'username': username,
        'email': email,
        'levelId': levelId,
        'pendingPoints': pendingPoints,
        'spendablePoints': spendablePoints,
        'totalPoints': totalPoints,
        'warningCount': warningCount,
      };
}
