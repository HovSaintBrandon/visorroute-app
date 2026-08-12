import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/json_helpers.dart';

class SignupRequest {
  final String id;

  /// 'student' | 'supervisor'
  final String role;

  /// 'pending' | 'approved' | 'rejected'
  final String status;
  final String? zoneName;
  final String name;

  // Student-only
  final String? regNo;
  final String? programme;
  final String? supervisorName;
  final String? workStationName;

  // Supervisor-only
  final String? email;
  final String? phone;
  final String? staffId;

  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? createdAccountId;
  final DateTime createdAt;

  SignupRequest({
    required this.id,
    required this.role,
    required this.status,
    this.zoneName,
    required this.name,
    this.regNo,
    this.programme,
    this.supervisorName,
    this.workStationName,
    this.email,
    this.phone,
    this.staffId,
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    this.createdAccountId,
    required this.createdAt,
  });

  /// `zoneId`/`supervisorId` come back populated as `{_id, name}` only —
  /// flattened straight to zoneName/supervisorName rather than kept as
  /// nested objects, since that's all this doc ever exposes.
  factory SignupRequest.fromJson(Map<String, dynamic> json) {
    final zone = json['zoneId'] as Map<String, dynamic>?;
    final supervisor = json['supervisorId'] as Map<String, dynamic>?;
    return SignupRequest(
      id: json['_id'] ?? json['id'] ?? '',
      role: json['role'] ?? '',
      status: json['status'] ?? 'pending',
      zoneName: zone?['name'] as String?,
      name: json['name'] ?? '',
      regNo: json['regNo'] as String?,
      programme: json['programme'] as String?,
      supervisorName: supervisor?['name'] as String?,
      workStationName: json['workStationName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      staffId: json['staffId'] as String?,
      reviewedBy: json['reviewedBy'] != null ? extractId(json['reviewedBy']) : null,
      reviewedAt: parseDateTime(json['reviewedAt']),
      rejectionReason: json['rejectionReason'] as String?,
      createdAccountId: json['createdAccountId'] != null ? extractId(json['createdAccountId']) : null,
      createdAt: parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class SignupRequestRepository {
  final Dio _dio;

  SignupRequestRepository(this._dio);

  Future<List<SignupRequest>> listRequests({String? status, String? role, int page = 1, int limit = 50}) async {
    try {
      final response = await _dio.get('/api/signup-requests', queryParameters: {
        if (status != null) 'status': status,
        if (role != null) 'role': role,
        'page': page,
        'limit': limit,
      });
      final data = (response.data as Map<String, dynamic>)['data'] as List<dynamic>;
      return data.map((r) => SignupRequest.fromJson(r as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SignupRequest> getRequest(String id) async {
    try {
      final response = await _dio.get('/api/signup-requests/$id');
      return SignupRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// 409 if the request isn't currently pending, 404 if it doesn't exist.
  Future<SignupRequest> approve(String id) async {
    try {
      final response = await _dio.patch('/api/signup-requests/$id/approve');
      return SignupRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SignupRequest> reject(String id, {String? reason}) async {
    try {
      final response = await _dio.patch('/api/signup-requests/$id/reject', data: {
        if (reason != null && reason.isNotEmpty) 'reason': reason,
      });
      return SignupRequest.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
