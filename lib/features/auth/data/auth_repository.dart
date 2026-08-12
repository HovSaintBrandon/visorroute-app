import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';

enum UserRole { supervisor, student, admin }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'supervisor':
      return UserRole.supervisor;
    case 'admin':
      return UserRole.admin;
    case 'student':
    default:
      return UserRole.student;
  }
}

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final UserRole role;

  AuthResult({required this.accessToken, required this.refreshToken, required this.role});

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      role: roleFromString(json['role'] as String?),
    );
  }
}

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<AuthResult> login({required String identifier, required String password}) async {
    try {
      final response = await _dio.post('/api/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      return AuthResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Tolerates failure by design — logout still tears down the local
  /// session below regardless of whether the server call succeeds.
  Future<void> logout(String refreshToken) async {
    try {
      await _dio.post('/api/auth/logout', data: {'refreshToken': refreshToken});
    } on DioException {
      // ignored — see doc comment above.
    }
  }

  Future<List<ZoneOption>> getZones() async {
    try {
      final response = await _dio.get('/api/auth/zones');
      final data = response.data as List<dynamic>;
      return data.map((z) => ZoneOption.fromJson(z as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<SupervisorOption>> getSupervisors() async {
    try {
      final response = await _dio.get('/api/auth/supervisors');
      final data = response.data as List<dynamic>;
      return data.map((s) => SupervisorOption.fromJson(s as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SignupResult> signupStudent({
    required String name,
    required String regNo,
    required String programme,
    required String zoneId,
    required String supervisorId,
    required String password,
    required String workStationName,
  }) async {
    try {
      final response = await _dio.post('/api/auth/signup', data: {
        'role': 'student',
        'name': name,
        'regNo': regNo,
        'programme': programme,
        'zoneId': zoneId,
        'supervisorId': supervisorId,
        'password': password,
        'workStationName': workStationName,
      });
      return SignupResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SignupResult> signupSupervisor({
    required String name,
    required String email,
    required String phone,
    required String staffId,
    required String zoneId,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/api/auth/signup', data: {
        'role': 'supervisor',
        'name': name,
        'email': email,
        'phone': phone,
        'staffId': staffId,
        'zoneId': zoneId,
        'password': password,
      });
      return SignupResult.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

class ZoneOption {
  final String id;
  final String name;

  ZoneOption({required this.id, required this.name});

  factory ZoneOption.fromJson(Map<String, dynamic> json) {
    return ZoneOption(id: json['_id'] ?? json['id'] ?? '', name: json['name'] ?? '');
  }
}

class SupervisorOption {
  final String id;
  final String name;
  final String zoneId;

  SupervisorOption({required this.id, required this.name, required this.zoneId});

  factory SupervisorOption.fromJson(Map<String, dynamic> json) {
    return SupervisorOption(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      zoneId: json['zoneId']?.toString() ?? '',
    );
  }
}

/// `202 { status: "pending", signupRequestId }` — no tokens are returned.
/// The caller must route to a pending-approval screen, not a logged-in state.
class SignupResult {
  final String status;
  final String signupRequestId;

  SignupResult({required this.status, required this.signupRequestId});

  factory SignupResult.fromJson(Map<String, dynamic> json) {
    return SignupResult(
      status: json['status'] ?? 'pending',
      signupRequestId: json['signupRequestId'] ?? '',
    );
  }
}
