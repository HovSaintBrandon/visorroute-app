/// A stop on a route, as returned by `GET /routes/:routeRunId`'s populated
/// `orderedStudentIds` (`{_id,name,regNo,workStation,status}` — a distinct,
/// slimmer projection than the full Student doc).
class RouteStop {
  final String studentId;
  final String name;
  final String regNo;
  final String workstationName;
  final bool visited;
  final bool assessed;

  RouteStop({
    required this.studentId,
    required this.name,
    required this.regNo,
    required this.workstationName,
    required this.visited,
    required this.assessed,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final workStation = json['workStation'] as Map<String, dynamic>?;
    final status = json['status'] as Map<String, dynamic>?;
    return RouteStop(
      studentId: json['_id'] ?? '',
      name: json['name'] ?? '',
      regNo: json['regNo'] ?? '',
      workstationName: workStation?['rawName'] ?? '',
      visited: status?['visited'] ?? false,
      assessed: status?['assessed'] ?? false,
    );
  }
}

class RouteRun {
  final String id;
  final String supervisorId;
  final String zoneId;
  final List<String> orderedStudentIds;

  /// Only present when this RouteRun came from `GET /routes/:routeRunId`
  /// (which populates stops) — `POST /routes/optimize` and the
  /// advance/abandon PATCHes return bare ids, so this stays null then.
  final List<RouteStop>? stops;
  final int currentIndex;

  /// 'in_progress' | 'completed' | 'abandoned'
  final String status;
  final DateTime startedAt;

  bool get isActive => status == 'in_progress';

  RouteRun({
    required this.id,
    required this.supervisorId,
    required this.zoneId,
    required this.orderedStudentIds,
    this.stops,
    required this.currentIndex,
    required this.status,
    required this.startedAt,
  });

  factory RouteRun.fromJson(Map<String, dynamic> json) {
    final rawStudents = json['orderedStudentIds'] as List<dynamic>? ?? [];
    final isPopulated = rawStudents.isNotEmpty && rawStudents.first is Map;

    return RouteRun(
      id: json['_id'] ?? json['id'] ?? '',
      supervisorId: json['supervisorId'] ?? '',
      zoneId: json['zoneId'] ?? '',
      orderedStudentIds: isPopulated
          ? rawStudents.map((s) => (s as Map<String, dynamic>)['_id'] as String).toList()
          : rawStudents.map((s) => s as String).toList(),
      stops: isPopulated
          ? rawStudents.map((s) => RouteStop.fromJson(s as Map<String, dynamic>)).toList()
          : null,
      currentIndex: json['currentIndex'] ?? 0,
      status: json['status'] ?? 'in_progress',
      startedAt: json['date'] != null
          ? DateTime.parse(json['date'])
          : (json['startedAt'] != null ? DateTime.parse(json['startedAt']) : DateTime.now()),
    );
  }

  RouteRun copyWith({int? currentIndex, String? status, List<RouteStop>? stops}) {
    return RouteRun(
      id: id,
      supervisorId: supervisorId,
      zoneId: zoneId,
      orderedStudentIds: orderedStudentIds,
      stops: stops ?? this.stops,
      currentIndex: currentIndex ?? this.currentIndex,
      status: status ?? this.status,
      startedAt: startedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'supervisorId': supervisorId,
        'zoneId': zoneId,
        'orderedStudentIds': orderedStudentIds,
        'currentIndex': currentIndex,
        'status': status,
        'startedAt': startedAt.toIso8601String(),
      };
}
