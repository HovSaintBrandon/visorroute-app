import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/json_helpers.dart';

class ZoneCoverageReport {
  final String zoneId;
  final int totalStudents;
  final int visited;
  final int assessed;
  final double visitedPercent;
  final double assessedPercent;

  ZoneCoverageReport({
    required this.zoneId,
    required this.totalStudents,
    required this.visited,
    required this.assessed,
    required this.visitedPercent,
    required this.assessedPercent,
  });

  factory ZoneCoverageReport.fromJson(Map<String, dynamic> json) {
    return ZoneCoverageReport(
      zoneId: extractId(json['zoneId']),
      totalStudents: json['totalStudents'] ?? 0,
      visited: json['visited'] ?? 0,
      assessed: json['assessed'] ?? 0,
      visitedPercent: (json['visitedPercent'] as num?)?.toDouble() ?? 0.0,
      assessedPercent: (json['assessedPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SupervisorCompletionReport {
  final String supervisorId;
  final int totalStudents;
  final int visited;
  final int assessed;
  final double visitedPercent;
  final double assessedPercent;
  final int visitsInRange;

  SupervisorCompletionReport({
    required this.supervisorId,
    required this.totalStudents,
    required this.visited,
    required this.assessed,
    required this.visitedPercent,
    required this.assessedPercent,
    required this.visitsInRange,
  });

  factory SupervisorCompletionReport.fromJson(Map<String, dynamic> json) {
    return SupervisorCompletionReport(
      supervisorId: extractId(json['supervisorId']),
      totalStudents: json['totalStudents'] ?? 0,
      visited: json['visited'] ?? 0,
      assessed: json['assessed'] ?? 0,
      visitedPercent: (json['visitedPercent'] as num?)?.toDouble() ?? 0.0,
      assessedPercent: (json['assessedPercent'] as num?)?.toDouble() ?? 0.0,
      visitsInRange: json['visitsInRange'] ?? 0,
    );
  }
}

class OverdueStudent {
  final String id;
  final String name;
  final String regNo;
  final DateTime? attachmentEndDate;
  final String? zoneName;
  final String? supervisorName;

  OverdueStudent({
    required this.id,
    required this.name,
    required this.regNo,
    this.attachmentEndDate,
    this.zoneName,
    this.supervisorName,
  });

  /// `zoneId`/`supervisorId` here are populated sub-docs containing only a
  /// name (plus their own id) — not full Zone/Supervisor docs.
  factory OverdueStudent.fromJson(Map<String, dynamic> json) {
    final attachment = json['attachment'] as Map<String, dynamic>?;
    final zone = json['zoneId'] as Map<String, dynamic>?;
    final supervisor = json['supervisorId'] as Map<String, dynamic>?;
    return OverdueStudent(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      regNo: json['regNo'] ?? '',
      attachmentEndDate: parseDateTime(attachment?['endDate']),
      zoneName: zone?['name'] as String?,
      supervisorName: supervisor?['name'] as String?,
    );
  }
}

class TimeToVisitEntry {
  final String studentId;
  final String regNo;

  /// null means no visit logged yet — never a placeholder 0.
  final int? daysToFirstVisit;

  TimeToVisitEntry({required this.studentId, required this.regNo, this.daysToFirstVisit});

  factory TimeToVisitEntry.fromJson(Map<String, dynamic> json) {
    return TimeToVisitEntry(
      studentId: json['studentId'] ?? '',
      regNo: json['regNo'] ?? '',
      daysToFirstVisit: json['daysToFirstVisit'] as int?,
    );
  }
}

class ReportsRepository {
  final Dio _dio;

  ReportsRepository(this._dio);

  Future<ZoneCoverageReport> getZoneCoverage(String zoneId) async {
    try {
      final response = await _dio.get('/api/reports/zone-coverage', queryParameters: {'zoneId': zoneId});
      return ZoneCoverageReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SupervisorCompletionReport> getSupervisorCompletion({String? supervisorId, DateTime? from, DateTime? to}) async {
    try {
      final response = await _dio.get('/api/reports/supervisor-completion', queryParameters: {
        if (supervisorId != null) 'supervisorId': supervisorId,
        if (from != null) 'from': from.toIso8601String(),
        if (to != null) 'to': to.toIso8601String(),
      });
      return SupervisorCompletionReport.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<OverdueStudent>> getOverdue({int? withinDays}) async {
    try {
      final response = await _dio.get('/api/reports/overdue', queryParameters: {
        if (withinDays != null) 'withinDays': withinDays,
      });
      final data = response.data as List<dynamic>;
      return data.map((s) => OverdueStudent.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<TimeToVisitEntry>> getTimeToVisit(String zoneId) async {
    try {
      final response = await _dio.get('/api/reports/time-to-visit', queryParameters: {'zoneId': zoneId});
      final data = response.data as List<dynamic>;
      return data.map((s) => TimeToVisitEntry.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Export is behind the same auth middleware as everything else — no
  /// query-param token escape hatch, so this can't be handed to
  /// url_launcher as a raw URL; the bytes have to be fetched authenticated
  /// and then saved/shared locally.
  Future<List<int>> exportReport(String type, String format) async {
    try {
      final response = await _dio.get<List<int>>(
        '/api/reports/$type/export',
        queryParameters: {'format': format},
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data!;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
