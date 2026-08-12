import 'package:dio/dio.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared_models/supervisor.dart';

class SupervisorRepository {
  final Dio _dio;

  SupervisorRepository(this._dio);

  Future<Supervisor> getMe() async {
    try {
      final response = await _dio.get('/api/supervisors/me');
      return Supervisor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// At least one of [phone]/[email] must be provided — the API 400s
  /// otherwise, so callers should validate before invoking this.
  Future<Supervisor> updateMe({String? phone, String? email}) async {
    try {
      final response = await _dio.patch('/api/supervisors/me', data: {
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
      });
      return Supervisor.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> pingLocation({required double lat, required double lng}) async {
    try {
      await _dio.patch('/api/supervisors/me/location', data: {'lat': lat, 'lng': lng});
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
